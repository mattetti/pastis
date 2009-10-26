require 'digest/md5'
require 'digest/sha1'

class Pastis
  include Logs
  
  module Parser
    
    class ParserError < StandardError; end

    def extract_link(item)
      if XML_PARSER == 'nokogiri'
        item.xpath('link').first.content
      elsif XML_PARSER == 'rexml'
        item.elements['link'].text
      else
        raise 'wow, how did you manage to not have a XML parser set?'
      end
    end

    def extract_timestamp(item)
      if XML_PARSER == 'nokogiri'
        date = item.xpath('pubDate').first.content
      elsif XML_PARSER == 'rexml'
        date = item.elements['pubDate'].text
      else
        raise ParserError, 'wow, how did you manage to not have a XML parser set?'
      end
      ::DateTime.parse(date).strftime("%F-%T").gsub(':', '_')
    end

    def extract_guid(item)
      if XML_PARSER == 'nokogiri'
        if !item.xpath('guid').empty?
          date = item.xpath('guid').first.content
        else
          date = Digest::MD5.hexdigest(item.xpath('link').first.content)
        end
      elsif XML_PARSER == 'rexml'
        if item.elements['guid']
          date = item.elements['guid'].text
        else
          date = Digest::MD5.hexdigest(item.elements['link'].text)
        end
      else
        raise ParserError,'wow, how did you manage to not have a XML parser set?'
      end
    end
    
    def extract_title(item)
      if XML_PARSER == 'nokogiri'
        date = item.xpath('title').first.content
      elsif XML_PARSER == 'rexml'
        date = item.elements['title'].text
      else
        raise ParserError,'wow, how did you manage to not have a XML parser set?'
      end
    end
    
    def extract_enclosure(item)
      if XML_PARSER == 'nokogiri'
        item.xpath('enclosure').first.attributes['url']
      elsif XML_PARSER == 'rexml'
        item.elements['enclosure'].attributes['url'] 
      else
        raise ParserError,'wow, how did you manage to not have a XML parser set?'
      end  
    end
    
    def add_to_transmission_queue(torrent_path, download_destination)
      if download_destination && defined?(Transmission)
        Transmission.add_to_queue(torrent_path, download_destination)
      end
    end 
    
    # TODO please please please clean up that mess [Matt]
    def download_torrent(item, path_to_save=nil)
      Dir.mkdir(TORRENTS_LOCAL_PATH) unless File.exist?(TORRENTS_LOCAL_PATH)
      Dir.mkdir(TORRENTS_LOCAL_PATH + '/to_download/') unless File.exist?(TORRENTS_LOCAL_PATH + '/to_download/')
      
      begin 
        link = extract_link(item)
        guid = extract_guid(item)
        timestamp = extract_timestamp(item)
        title = extract_title(item)
        url  = URI.parse(link.gsub(/\[(.+?)\]/){|grp| "~#{$1}~"})
        path  = url.path
      rescue => e
        # raise ParserError, e.message
        p "#{e.message} [#{__FILE__} Line #{__LINE__}]" 
      else
        if not_in_logs?(guid)
          res = Net::HTTP.start(url.host, url.port) {|http| http.get( url.path.gsub(/~(.*)~/){|grp| "[#{$1}]"} )}
          if res['content-disposition']
            filename = res['content-disposition'][/filename="(.*)";/, 1]
            torrent_path, download_destination = find_torrents_path_to_user(title, filename)
            File.open(torrent_path, 'w'){|file| file << res.body}
            add_to_transmission_queue(file, destination)
            add_to_logs(guid, filename, timestamp) 
          elsif enclosure_link = extract_enclosure(item)
            link =~ /.*\/(.*\.torrent)/
            filename = $1
            if filename
              torrent_path, download_destination = find_torrents_path_to_user(title, filename)
              File.open(torrent_path, 'w'){|file| file << res.body}
              add_to_transmission_queue(torrent_path, download_destination)
              add_to_logs(guid, filename, timestamp)  
            else
              puts "couldn't find out the filename of the enclosure"
            end
          else
            puts "skipping #{title} since it doesn't have a torrent file attached"
          end 
        end 
      end
    end 
    
    # returns an array with the torrent path and the torrent destination if available
    def find_torrents_path_to_user(title, filename)
      if FILTERS && FILTERS.map{|filter| filter.to_download?(title)}.uniq.include?(true) 
        [File.join(TORRENTS_LOCAL_PATH, 'to_download', filename), FILTERS.detect{|filter| filter.to_download?(title)}.location ]
      else
        [File.join(TORRENTS_LOCAL_PATH, filename), nil]
      end
    end
    
  end # of Parsee
end