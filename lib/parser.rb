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
        date = item.xpath('guid').first.content
      elsif XML_PARSER == 'rexml'
        date = item.elements['guid'].text
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

    def download_torrent(item, path_to_save=nil)
      Dir.mkdir(TORRENTS_LOCAL_PATH) unless File.exist?(TORRENTS_LOCAL_PATH)
      Dir.mkdir(TORRENTS_LOCAL_PATH + '/to_download/') unless File.exist?(TORRENTS_LOCAL_PATH + '/to_download/')
      
      begin
        link = extract_link(item)
        guid = extract_guid(item)
        timestamp = extract_timestamp(item)
        title = extract_title(item)
        url  = URI.parse(link)
        path  = url.path
      rescue => e
        # raise ParserError, e.message
        p "#{e.message} [#{__FILE__} Line #{__LINE__}]" 
      else
        if not_in_logs?(guid)
          res = Net::HTTP.start(url.host, url.port) {|http| http.get(url.path)}
          if res['content-disposition']
            filename = res['content-disposition'][/filename="(.*)";/, 1]
            torrent_path = find_torrents_path_to_user(title, filename)
            File.open(torrent_path, 'w'){|file| file << res.body}
            add_to_logs(guid, filename, timestamp) 
          else
            puts "skipping #{title} since it doesn't have a torrent file attached"
          end 
        end 
      end
    end 
    
    def find_torrents_path_to_user(title, filename) 
      if FILTERS && FILTERS.map{|filter| filter.to_download?(title)}.uniq.include?(true) 
        File.join(TORRENTS_LOCAL_PATH, 'to_download', filename)
      else
        File.join(TORRENTS_LOCAL_PATH, filename)
      end
    end
    
  end # of Parsee
end