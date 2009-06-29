require File.join(File.dirname(__FILE__), 'ricard_plugin_base')

module Ricard
  
  class Plugin 
    
    include ::Ricard::PluginBase
    class RicardPluginError < StandardError; end
    class DnsError < StandardError; end
    
    def self.dns_cache
      @dns_cache ||= {}
    end
    
    def self.domain_to_ip(domain)
      return dns_cache[domain] if dns_cache[domain]
      route_results = `traceroute #{domain}` 
      # looking up the ip since calling the server using the domain won't work :(
      ip = route_results[/\((.*)\)/, 1]
      ip ? ip : raise(DnsError, "no ip was found for #{domain}")
    end
    
    ####### COMMANDS #########
    
    
    # returns the local info
    # meant to be called by the client
    # and returns the server info
    def wol_info
      @wol_info ||= [Mac.address, Ricard::Plugin.domain_to_ip(`hostname`)].map{|item| Base64.encode64(item) }.join(';') + ";"
    end
    
  end
    
end