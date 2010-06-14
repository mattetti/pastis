require 'URI'
require 'net/http'
require 'json'
require 'yaml'
require 'pathname'

root = Pathname.new File.expand_path(File.dirname(__FILE__))
# only loading the required files if we are outside of a Cocoa app
if File.exist?(root.join('lib/rss_parser.rb'))
  STANDALONE = true
  require root.join('lib/rss_parser')
  require root.join('lib/filter')
  require root.join('lib/logs')
  require root.join('vendor/macruby_http')
else
  # load from the resources folder
  STANDALONE = false
  require root.join('rss_parser')
  require root.join('filter')
  require root.join('logs')
  require root.join('macruby_http')
end

class Pastis  
  
  include MacRubyHelper::DownloadHelper
  include Logs
  
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
    MacRubyHTTP.post(transmission_rpc, {:payload => payload, :blocking => true, :headers => @headers}) do |resp|
      if resp.status_code == 409
        @headers['X-Transmission-Session-Id'] = resp.headers['X-Transmission-Session-Id']
        # retry with the proper session
        add_to_transmission_queue(torrent_path, download_destination)
      elsif resp.status_code == 200
        @t_added ||= []
        puts "[added] #{torrent_path}" unless @t_added.include?(torrent_path)
        @t_added << torrent_path
      else
        puts "something went wrong when adding torrent to download: \n#{resp.inspect}"
      end
    end
  end
  
  def filters
    begin
      @filters ||= YAML.load_file(filters_path).map{|raw| ::Pastis::Filter.new(raw)}
    rescue Exception => e
      if e.message =~ /No such file or directory/
        puts "Default filters are missing, creating one now."
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
    
    if not_in_logs?(item.guid)
      url = item.enclosure['url']
      filename = NSURL.URLWithString(url).lastPathComponent
      puts "[new] #{filename}"
      torrent_path, download_destination = find_torrents_path_to_user(item.title, filename)
      download url, :immediate => true, :save_to => torrent_path, :url => url do |torrent|
        if torrent.status_code == 200          
          add_to_transmission_queue(torrent_path, download_destination) if download_destination
          add_to_logs(item.guid, filename, item.pubDate)
        end
      end
    end
    
  end

  def check(url="http://www.ezrss.it/feed/")
    # Checking that transmission is running, start it otherwise
    running_apps = NSWorkspace.sharedWorkspace.runningApplications.map{|app| app.localizedName}
    unless running_apps.include?('Transmission')
      puts "Transmission not Running, starting now..."
      NSWorkspace.sharedWorkspace.launchApplication('Transmission')
    end
      
    RSSParser.new(url).parse do |item|
      download_torrent(item)
    end
    save_logs
    prune
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
     Dir.glob("#{torrents_local_path}*.torrent").each do |file|
       File.delete(file) if (File.atime(File.expand_path(file)) < (Time.now - (60 * 60 * 24 * 31)))
     end
   end
  
end