#!/usr/bin/ruby

require 'rubygems'
require 'net/http'
require 'uri'
require 'date'
require 'logs'
include Logs
begin
  require 'nokogiri'
rescue LoadError
  require "rexml/document"
  XML_PARSER = 'rexml'
else
  XML_PARSER = 'nokogiri'
end
 

BASE_URL            = "http://pipes.yahoo.com"
FEED_URI            = "/pipes/pipe.run?_id=7aa6281616ea0a8cb27aaa0914f09a76&_render=rss"
TORRENTS_LOCAL_PATH = File.expand_path("./torrents/")

def feed
  url = URI.parse(BASE_URL)
  res = Net::HTTP.start(url.host, url.port) {|http| http.get(FEED_URI) }
  res.body 
end 

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

