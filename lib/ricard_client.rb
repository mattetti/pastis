require 'dnssd'
require 'base64'

module Ricard 
  class Client 
    attr_reader :options, :server_info
    
    class DiscoveryError < StandardError; end
    ServerInfo = Struct.new(:ip, :port, :domain)
    
    def initialize(options={})
      default_options = {
        :timeout => 3
      }
      @options = default_options.merge(options)
    end
     
    # Returns an array with the server ip, port and domain
    def discover_ricard_server
      return server_info if server_info
      server_discovery = DNSSD.resolve('ricard', '_ricard._tcp', 'local') do |r|
        route_results = `traceroute #{r.target}` 
        # looking up the ip since calling the server using the domain won't work :(
        ip = route_results[/\((.*)\)/,1] 
        raise ::Ricard::Client::DiscoveryError, "The ricard server wasn't found on the LAN" unless ip
        @server_info = ServerInfo.new(ip, r.port, r.target)
        puts "Found the Ricard service at #{@server_info.domain} #{@server_info.port} on ip: #{@server.ip}"
      end
      sleep options[:timeout]
      server_discovery.stop
      raise ::Ricard::Client::DiscoveryError, "No Ricard server found on the LAN, make sure you started a server" unless server_info
      server_info
    end
    
    def send_command(command, plugin='ricard')
      puts "Sending: '#{command}' to the #{plugin} Ricard Server plugin"
      ricard_server = discover_ricard_server

      data = [plugin, command].map do |s| 
        Base64.encode64(s)
      end.join(';') + ";"

      ricard = TCPSocket.new(ricard_server.ip, ricard_server.port)  #.send(data, 0)
      ricard.send(data, 0)
      puts ricard.recv(100)
      ricard.close    
    end
    
  end
end