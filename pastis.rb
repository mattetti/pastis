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

# Requirements: transmission-client gem from gemcutter

require 'rubygems'
require 'net/http'
require 'uri'
require 'date' 
require 'yaml'
begin
  require 'transmission-client'
  puts "Transmission bridge enabled, don't forget to turn it on."
rescue
  puts "You need to install the transmission-client gem to feed transmission."
else
  require File.expand_path('lib/transmission')
end
ROOT = File.expand_path(File.dirname(__FILE__))
# Dir.glob(ROOT + "/lib/*.rb").each{|file| require File.expand_path(file)}
# let's not load ricard for now
require File.expand_path('lib/logs')
require File.expand_path('lib/parser')
require File.expand_path('lib/filter')
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
  DEFAULT_FEED        = "http://www.ezrss.it/feed/" #"http://pipes.yahoo.com/pipes/pipe.run?_id=7aa6281616ea0a8cb27aaa0914f09a76&_render=rss"
  TORRENTS_LOCAL_PATH = File.expand_path("./torrents/")     # AKA the glass
  PRUNE_FILES_AFTER   = Time.now - (60 * 60 * 24 * 31)                                              
  raise "You need to have a pastis_filters.yml file, check the example file" unless File.exist?(ROOT + "/filters.yml")
  FILTERS             = YAML.load_file(File.expand_path('~/pastis_filters.yml')).map{|raw| ::Pastis::Filter.new(raw)}
   
  attr_reader :client, :server 
   
  # def initialize
  #   @client = Ricard::Client.new
  # end
  
  # Deletes the old files
  def wash_the_dishes
    Dir.glob("#{TORRENTS_LOCAL_PATH}*.torrent").each do |file|
      File.delete(file) if (File.atime(File.expand_path(file)) < PRUNE_FILES_AFTER)
    end
  end
  
  # Get, parses the feed and download each link
  # Before finishing the work done is saved in the logs
  # and the old files are being deleted.
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
  
  # def send_command(command, plugin='ricard')
  #   client.send_command(command, plugin)
  # end
  
  # # Wakes up a sleeping machine using wake on lan
  # # 
  # # === Parameters
  # # mac_address <String> the mac address of the machine to wake.
  # # ip <String> the ip of the machine to wake.
  # #
  # # === Usage
  # # pastaga = Pastis.new
  # # pastage.wake("00:1c:42:00:00:00", "10.37.129.2")
  # #
  # def wake(mac_address, ip)
  #   wol = WakeOnLAN.new
  #   wol.setup(mac_address, ip)
  #   wol.send_wake
  # end
  # 
  # def wake_ricard
  #   wolinfo = send_command('wol_info')
  #   wake(wolinfo.first, wolinfo.last)
  # end
  # 
  # def start_ricard
  #   @server = Ricard::Server.new
  #   @server.start
  # end
  
  protected
  
  # query the feed and return the body
  def feed(url_string=nil)
    url_string ||= DEFAULT_FEED
    url = URI.parse(url_string)
    feed_uri =  url.query ? "#{url.path}?#{url.query}" : url.path
    req = Net::HTTP.start(url.host, url.port) {|http| http.get(feed_uri) }
    req.body 
  end 

end 