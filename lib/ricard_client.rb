require 'dnssd'
require 'base64'

module Ricard 
  class Client 
    attr_reader :options
    
    def initialize(options={})
      default_options = {
        :timeout => 3
      }
      @options = default_options.merge(options)
    end
    
    def send_command(command, plugin='ricard')
      puts "Sending: '#{command}' to the #{plugin} Ricard Server plugin"
      
      # DNSSD.resolve()
      
      # service = DNSSD.browse('_ricard._tcp') do |reply|
      #   server = reply
      #   data = [plugin, command].map do |s| 
      #     Base64.encode64(s)
      #   end.join(';') + ";"
      #   TCPSocket.new(r.target, r.port).send(data, 0)
      # end        
      # 
      # STDERR.puts "looking for the Ricard server (waiting 2 secs)"
      # service.stop
            
      server_discovery = DNSSD.resolve('ricard', '_ricard._tcp', 'local') do |r|
        puts "Found the Ricard service at #{r.target} #{r.port}"
        data = [plugin, command].map do |s| 
          Base64.encode64(s)
        end.join(';') + ";"
        TCPSocket.new(r.target, r.port).send(data, 0)
      end  
      
      sleep options[:timeout]
      server_discovery.stop
    end
  end
end