# wakeonlan.rb - Wake a sleeping computer from another machine on the network
# Copyright (C) 2004 Kevin R. Bullock <kbullock@ringworld.org>
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
# 

WOL_VERSION = "wakeonlan.rb version 0.2.1"

require 'socket'

class WakeOnLAN
    
    include Socket::Constants
    
    # Exceptions
    class AddressException < RuntimeError; end
    class SetupException < RuntimeError; end
    
    # Regular Expression constants for hardware and IP addresses
    RE_MAC_ADDR = Regexp.new( '^' + (('[0-9A-Fa-f]' * 2).to_a * 6).join(':') + '$' )
    RE_IP_ADDR = Regexp.new( '^' + ('(([0-9][0-9]?)|([01][0-9][0-9])|(2[0-4][0-9])|(2[0-5][0-5]))'.to_a * 4).join('\.') + '$' )
    
    # Constructor method
    def initialize( mac = nil, ip = nil )
        
        if mac.nil?
            @magic = nil; @ip_addr = nil
        elsif ip.nil?
            self.setup( mac )
        else
            self.setup( mac, ip )
        end
        
    end #initialize()
    
    # Packet set-up method. Keeping this out of the constructor allows a
    # single WakeOnLAN object to be re-used for multiple addresses.
    def setup( mac, ip = '255.255.255.255' )
        
        @magic ||= ("\xff" * 6)
        
        # Validate MAC address and craft the magic packet
        raise AddressException,
            'Invalid MAC address' unless self.valid_mac?( mac )
        mac_addr = mac.split(/:/).collect {|x| x.hex}.pack('CCCCCC')
        @magic[6..-1] = (mac_addr * 16)
        
        # Validate IP address
        raise AddressException,
            'Invalid IP address' unless self.valid_ip?( ip )
        @ip_addr = ip
        
    end #set_up()
    
    def valid_mac?( mac )
        if mac =~ RE_MAC_ADDR then true
        else false
        end
    end #valid_mac?()
    
    def valid_ip?( ip )
        if ip =~ RE_IP_ADDR then true
        else false
        end
    end #valid_ip?()
    
    def send_wake()
        
        raise SetupException,
            'Tried to send packet without setting it up' unless @magic
        
        sock = UDPSocket.new
        sock.setsockopt( SOL_SOCKET, SO_BROADCAST, 1 )
        sock.connect( @ip_addr, Socket.getservbyname( 'discard', 'udp' ) )
        sock.send( @magic, 0 )
        
    end #send_wake()

end #class WakeOnLAN