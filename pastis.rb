require 'json'
require 'yaml'

dir_path = NSBundle.mainBundle.resourcePath.fileSystemRepresentation

# only loading the required files if we are outside of a Cocoa app
if File.exist?(File.expand_path('lib/rss_parser.rb', dir_path))
  STANDALONE = true
  require File.expand_path('lib/rss_parser', dir_path)
  require File.expand_path('lib/filter', dir_path)
  require File.expand_path('lib/logs', dir_path)
  require File.expand_path('vendor/macruby_http', dir_path)
  require File.expand_path('lib/logger', dir_path)
else
  # load from the resources folder
  STANDALONE = false
  require File.expand_path('rss_parser', dir_path)
  require File.expand_path('filter', dir_path)
  require File.expand_path('logs', dir_path)
  require File.expand_path('macruby_http', dir_path)
  require File.expand_path('logger', dir_path)
end

BW = BubbleWrap unless defined?(BW)

module BubbleWrap
  
  SETTINGS = {}
  module_function
  
  def debug=(val)
    BubbleWrap::SETTINGS[:debug] = val
  end

  def debug?
    BubbleWrap::SETTINGS[:debug]
  end

  # @return [UIcolor]
  def rgb_color(r,g,b)
    rgba_color(r,g,b,1)
  end
  
  # @return [UIcolor]
  def rgba_color(r,g,b,a)
    UIColor.colorWithRed((r/255.0), green:(g/255.0), blue:(b/255.0), alpha:a)
  end
  
  def localized_string(key, value)
    NSBundle.mainBundle.localizedStringForKey(key, value:value, table:nil)
  end
  
  def create_uuid
    uuid = CFUUIDCreate(nil)
    CFUUIDCreateString(nil, uuid)
  end
  
end

# BubbleWrap.debug = true

class Pastis
  
  include BubbleWrap
  
  def self.logger
    @logger ||= Logger.new
  end
  
  def torrents_local_path
    path = NSUserDefaults.standardUserDefaults['pastis.torrents_path']
    unless path
      # Default
      path = "~/torrents".stringByStandardizingPath
      NSUserDefaults.standardUserDefaults['pastis.torrents_path'] = path
      NSUserDefaults.standardUserDefaults.synchronize # force sync
    end
    path
  end
  
  def filters_path
    path = NSUserDefaults.standardUserDefaults['pastis.filters_path']
    # create default filters if not available
    path ? path : create_default_filters
  end
  
  def create_default_filters
    path = "~/pastis_filters.yml".stringByStandardizingPath
    # create default filter
    File.open(path, 'w'){|f| f << Pastis::Filter.default.to_yaml}
    NSUserDefaults.standardUserDefaults['pastis.filters_path'] = path
    NSUserDefaults.standardUserDefaults.synchronize # force sync
    path
  end
  
  def add_to_transmission_queue(torrent_path, download_destination)
    transmission_rpc = "http://localhost:9091/transmission/rpc"
    payload = { 'method'    => 'torrent-add',
                'arguments' => {'filename'     => File.expand_path(torrent_path), 
                                'download-dir' => File.expand_path(download_destination)} 
               }.to_json
    @headers ||= {}
    HTTP.post(transmission_rpc, {:payload => payload, :blocking => true, :headers => @headers}) do |resp|
      if resp.status_code == 409
        @headers['X-Transmission-Session-Id'] = resp.headers['X-Transmission-Session-Id']
        # retry with the proper session
        add_to_transmission_queue(torrent_path, download_destination)
      elsif resp.status_code == 200
        @t_added ||= []
        Pastis.logger << "[added] #{torrent_path}" unless @t_added.include?(torrent_path)
        @t_added << torrent_path
      else
        Pastis.logger << "something went wrong when adding torrent to download: \n#{resp.inspect}"
      end
    end
  end
  
  def filters
    begin
      @filters ||= YAML.load_file(filters_path).map{|raw| ::Pastis::Filter.new(raw)}
    rescue Exception => e
      if e.message =~ /No such file or directory/
        Pastis.logger << "Default filters are missing, creating one now."
        create_default_filters
        retry
      else
        raise e
      end
    end
  end
  
  def download_torrent(item, path_to_save=nil)
    Dir.mkdir(torrents_local_path) unless File.exist?(torrents_local_path)
    download_path = File.join(torrents_local_path , 'to_download')
    Dir.mkdir(download_path) unless File.exist?(download_path)
    url = item.enclosure['url']
    if !url.include?(".torrent") && item.title.include?(".torrent")
      filename = item.title.strip
      else
      filename = NSURL.URLWithString(url).lastPathComponent
    end
    guid = (item.guid.nil? || item.guid.empty?) ? filename : item.guid
    item.guid = guid
    
    unless Logs.include?(item.guid)
      
      Pastis.logger << "[new] #{item.title} #{filename} - #{url}"
      torrent_path, download_destination = find_torrents_path_to_user(item.title, filename)

      HTTP.get(url, :timeout => 15.0, :save_to => torrent_path.dup,
               :destination => (download_destination ? download_destination.dup : nil),
               :item => item.dup,
               :file => filename.dup) do |response, query|
        
                next if Logs.include?(item.guid)
                  if response.status_code == 200
                    response.body.writeToFile(query.options[:save_to], atomically:true)
                    destination = query.options[:destination]
                    if destination
                      Pastis.logger << "Queuing: #{item.title} - #{query.options[:file]}"
                    else
                      Pastis.logger << "Downloaded: #{item.title} - #{query.options[:file]}"
                    end
               
                    add_to_transmission_queue(query.options[:save_to], destination) if destination
                    Logs.add query.options[:item].guid, query.options[:file], query.options[:item].pubDate
                    @to_dl_count -= 1
                    Logs.save if @to_dl_count.zero?
                  elsif response.error_message
                    Pastis.logger << "#{response.error_message} for #{query.url.absoluteString}"
                  end
      end
  
    end
    
  end

  def check(url=nil)
    # Checking that transmission is running, start it otherwise
    running_apps = NSWorkspace.sharedWorkspace.runningApplications.map{|app| app.localizedName}
    unless running_apps.include?('Transmission')
      Pastis.logger << "Transmission not Running, starting now..."
      NSWorkspace.sharedWorkspace.launchApplication('Transmission')
    end
    @to_dl_count = 0
    url ||= torrent_rss   
    feed = RSSParser.new(url)
    feed.delegate = self
    feed.parse do |item|
      if Logs.include?(item.guid)
        Pastis.logger << "#{item.title} #{item.enclosure['url']} already downloaded"
      else
        @to_dl_count += 1
        download_torrent(item)
      end
    end
  end
  
  def torrent_rss
    feed = NSUserDefaults.standardUserDefaults['pastis.torrent_rss']
    if feed.nil?
      # feed = "http://rss.bt-chat.com/?group=3&cat=9" #"http://rss.bt-chat.com/"
        feed = "http://showrss.karmorra.info/feeds/all.rss" #"http://www.ezrss.it/feed/"
      NSUserDefaults.standardUserDefaults['pastis.torrent_rss'] = feed
      NSUserDefaults.standardUserDefaults.synchronize
    end
    feed
  end
  
  # returns an array with the torrent path and the torrent destination if available
  def find_torrents_path_to_user(title, filename)
    if filters.map{|filter| filter.to_download?(title)}.uniq.include?(true) 
      [File.join(torrents_local_path, 'to_download', filename), filters.detect{|filter| filter.to_download?(title)}.location ]
    else
      [File.join(torrents_local_path, filename), nil]
    end
  end
  
  # Deletes the old files
   def prune
     Dir.glob(File.join(torrents_local_path, "*.torrent")).each do |file|
       File.delete(file) if (File.atime(File.expand_path(file)) < (Time.now - (60 * 60 * 24 * 31)))
     end
   end

  def when_parser_is_done
    Logs.save # to save last run
    prune
  end
  
end