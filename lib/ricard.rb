require 'dnssd'
require 'eventmachine'
require 'base64'

# Bonjour server handling requests from the LAN
# using the Ricard client.
module Ricard
  VERSION = '0.1.0'
  PROTOCOL_VERSION = '20090628'
  
  class Server
    attr_reader :options
    
    def initialize(options={})
      default_options = {
        :timeout => 5, 
        :port => 4280
      }
      @options = default_options.merge(options)
    end
        
    def start
      register_on_bonjour
      start_server
    end 
    
    protected
    
    def register_on_bonjour
      tr = DNSSD::TextRecord.new
      tr['description'] = "Ricard server for Pastis"
      
      DNSSD.register('ricard', '_ricard._tcp', 'local', options[:port], tr.encode) do |rr|
        puts "Ricard server announced to run on port #{options[:port]}"
      end
    end 
    
    def start_server
      EventMachine::run {
        EventMachine::start_server "127.0.0.1", options[:port], RicardEventServer
        puts "Listening for requests on #{options[:port]}"
      }
    end
    
  end
  
end 

module RicardEventServer
  def post_init 
    @data = ''
  end
  
  def receive_data(data)
    @data << data
    p "received data #{data}"
    if @data.scan(/;/).size == 2
      # B64 Encoded COMMAND;PLUGIN;
      command, plugin = data.split(';').map {|s| Base64.decode64(s) }
      # do something with the query
      $stderr.puts "Plugin: #{plugin}, Command: #{command}"
    end
  end
end