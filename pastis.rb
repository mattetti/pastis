#!/usr/bin/ruby

require 'rubygems'
require 'net/http'
require 'uri'
require 'date'
require 'lib/logs'
require 'lib/parser'
begin
  require 'nokogiri'
rescue LoadError
  require "rexml/document"
  XML_PARSER = 'rexml'
else
  XML_PARSER = 'nokogiri'
end

class Pastis
  include Parser 
  DEFAULT_FEED        = "http://pipes.yahoo.com/pipes/pipe.run?_id=7aa6281616ea0a8cb27aaa0914f09a76&_render=rss"
  TORRENTS_LOCAL_PATH = File.expand_path("./torrents/")     # AKA the glass
  
  def feed(url_string=DEFAULT_FEED)
    url = URI.parse(url_string)
    feed_uri =  url.query ? "#{url.path}?#{url.query}" : url.path
    res = Net::HTTP.start(url.host, url.port) {|http| http.get(feed_uri) }
    res.body 
  end
  
  # Start the download of the files
  def pour
    # Where everything starts
    if XML_PARSER == 'nokogiri'
      xml = ::Nokogiri::XML(feed)
      xml.xpath('//item').each do |el|
        puts el.xpath('title').first.content + "\n"
        puts el.xpath('pubDate').first.content + "\n"
        download_torrent(el)
        puts " ***\n"  
      end
    else
      xml = ::REXML::Document.new(feed) 
      xml.elements.each("//item") do |el| 
        puts el.elements['title'].text + "\n"
        puts el.elements['pubDate'].text + "\n"
        download_torrent(el)
        puts " ***\n" 
      end
    end
    save_logs
  end
  alias :run :pour

end  

Pastis.new.pour 

