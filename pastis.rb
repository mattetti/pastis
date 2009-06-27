#!/usr/bin/ruby

#################################### PASTIS ###################################
#                                                                             #
# Pastis is a simple script that downloads RSS feed links                     #
#                                                                             #
# Usage:                                                                      #                                                                             #
# Pastis.new.pour(http://toprssfeeds.com)                                     #
#                                                                             #
# Downloaded files get copied over to a folder and only get downloaded once   #
# even if you delete the file or the RSS feed refreshes.                      #
#                                                                             #
# A log of the downloads for the last 30 days is stored in the .rsslog file.  #
# You can simply delete the file to reset the logs.                           #
#                                                                             #
###############################################################################

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
  PRUNE_FILES_AFTER   = Time.now - (60 * 60 * 24 * 31)
  
  def feed(url_string=nil)
    url_string ||= DEFAULT_FEED
    url = URI.parse(url_string)
    feed_uri =  url.query ? "#{url.path}?#{url.query}" : url.path
    res = Net::HTTP.start(url.host, url.port) {|http| http.get(feed_uri) }
    res.body 
  end
  
  # delete the old files
  def wash_the_dishes
    Dir.glob("#{TORRENTS_LOCAL_PATH}*.torrent").each do |file|
      File.delete(file) if (File.new(file).atime < PRUNE_FILES_AFTER)
    end
  end
  
  # Start the download of the files
  def pour(url=nil)
    # Where everything starts
    if XML_PARSER == 'nokogiri'
      xml = ::Nokogiri::XML(feed(url))
      xml.xpath('//item').each do |el|
        puts el.xpath('title').first.content + "\n"
        puts el.xpath('pubDate').first.content + "\n"
        download_torrent(el)
        puts " ***\n"  
      end
    else
      xml = ::REXML::Document.new(feed(url)) 
      xml.elements.each("//item") do |el| 
        puts el.elements['title'].text + "\n"
        puts el.elements['pubDate'].text + "\n"
        download_torrent(el)
        puts " ***\n" 
      end
    end
    save_logs
    wash_the_dishes
  end

end  

Pastis.new.pour 