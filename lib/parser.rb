class Pastis
  include Logs
  
  module Parser

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
        raise 'wow, how did you manage to not have a XML parser set?'
      end
      ::DateTime.parse(date).strftime("%F-%T").gsub(':', '_')
    end

    def extract_guid(item)
      if XML_PARSER == 'nokogiri'
        date = item.xpath('guid').first.content
      elsif XML_PARSER == 'rexml'
        date = item.elements['guid'].text
      else
        raise 'wow, how did you manage to not have a XML parser set?'
      end
    end 

    def download_torrent(item, path_to_save=nil)
      Dir.mkdir(TORRENTS_LOCAL_PATH) unless File.exist?(TORRENTS_LOCAL_PATH)
      link = extract_link(item)
      guid = extract_guid(item)
      url  = URI.parse(link)
      path  = url.path

      timestamp = extract_timestamp(item)

      if not_in_logs?(guid)
        res = Net::HTTP.start(url.host, url.port) {|http| http.get(url.path)}
        filename = res['content-disposition'][/filename="(.*)";/, 1]
        torrent_path = File.join(TORRENTS_LOCAL_PATH, "#{timestamp}-#{filename}")
        File.open(torrent_path, 'w'){|file| file << res.body}
        add_to_logs(guid, filename, timestamp) 
      end
    end
  end
end