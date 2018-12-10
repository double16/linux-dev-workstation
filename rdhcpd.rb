' Copyright (c) 2007, Tony Ivanov
 All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
     * Redistributions of source code must retain the above copyright
       notice, this list of conditions and the following disclaimer.
     * Redistributions in binary form must reproduce the above copyright
       notice, this list of conditions and the following disclaimer in the
       documentation and/or other materials provided with the distribution.
     * Neither the name of the Tony Ivanov nor the
       names of its contributors may be used to endorse or promote products
       derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY Tony Ivanov ``AS IS'' AND ANY
 EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL Tony Ivanov BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'

#------------------------------------------------------------------------
# Configuration
#------------------------------------------------------------------------
interface = ARGV[0] || "192.168.0.1" # IP address of the interface wich you wish to bind on

network = interface.split('.')[0..2].collect { |n| n.to_i } + [0]

broadcast = interface.sub(/(\d+.\d+.\d+).\d+/,'\1.255') # meaning: broadcast = "192.168.4.255"

mask = "255.255.255.0"

gateway = interface

dns = ARGV[1] || "8.8.8.8"

leasetime = 60*60*24

# Mac Address Bind list:
@staticdb = []
# A few examples on how to bind mac addresses to static numbers.
#@staticdb[8] = "00:16:56:53:1e:5f" # My NDS bonded to 192.168.4.8
#@staticdb[12] = "00:02:c7:92:87:04" # My PSP bonded to 192.168.4.12







#------------------------------------------------------------------------
# CODE
#------------------------------------------------------------------------
#reserve your own ip.
@staticdb.each do |i| 
	if i != nil
		i.downcase!
	end
end
@database = @staticdb.clone
@database[interface.match(/\d+.\d+.\d+.(\d+)/).captures[0].to_i] = "RESERVED!"

def putlog(string)
	timestamp = Time.now.month.to_s + '/' + Time.now.day.to_s + " " +[Time.now.hour,Time.now.min,Time.now.sec].join(":") + '> '
	puts timestamp + string
end

def whois(mac)
	(1..254).each do |i| 
		if @database[i] == mac
			return i
		end
	end
	nil
end

def giveIpTo(mac) 	
	if @database.member?(mac)
		return whois(mac)
	end
	(1..254).each do |i| 
		if @database[i] == nil
			@database[i] = mac
			return i
		end
	end
	nil
end


 
  
class BootpPacket
	attr_accessor :op,:htype,:hlen,:hops,:xid,:secs,:flags,:ciaddr,:yiaddr,:nsiaddr,:radder,:macaddr,:cookie,:options
	def parse(d)
		@op,@htype,@hlen,@hops,@xid,@secs,@flags,@ciaddr,@yiaddr,@nsiaddr,@radder,@macaddr,@cookie,tmpOptions  = d.unpack("C4NnnN4a6x202Na*")
		@options={}
		offset =0	
		while offset != -1 and offset < tmpOptions.size		
			oid,len=tmpOptions.unpack("@"+ offset.to_s + "C2")
			offset += 2
			unless len.nil?
			    value=tmpOptions.unpack("@" + offset.to_s + "a" + len.to_s)
			    value = value[0]
			    offset += len
			end
			case oid
				when 0xff 
					offset = -1
				when 12
					@options[:hostname]= value
				when 53
					@options[:message_type] = value.unpack("C")[0]
				when 61
					#i'm ignoring this option for now, i assumed it's a dupe of macaddr and htype.
					@options[:htype_mac] = value
				when 55
					@options[:requests] = value.unpack("C*")
				when 50
					@options[:address_request] = value.unpack("CCCC")
				when 54
					@options[:dhcp_server] = value.unpack("CCCC")
				when 56 
					# It's a message!! =D
					putlog "MSG: " + value
				when 60
					putlog "VENDOR: " + value
				else
				    putlog "PANIC! Unknown dhcp option! Id:"+ oid.to_s + " value: " + value.inspect
			end
		end	
	end
	def new()
	end
	def macf
		ret=""
		@macaddr.unpack("HXhHXhHXhHXhHXhHXh")	.join.gsub(/([0-9a-f][0-9a-f])/i,':\1').sub(":","")
	end
	def toPacket()
		ret = [@op,@htype,@hlen,@hops,@xid,@secs,@flags,@ciaddr,@yiaddr,@nsiaddr,@radder,@macaddr,@cookie].pack("C4NnnN4a6x202N")
		options.each do |key|
			case key[0]
				when :message_type					
					ret+= [53,1,key[1]].pack("CCC")
				when :subnet_mask
					tmp = key[1].split('.')
					tmp2 =[]
					tmp.each do |c| tmp2.push c.to_i end
					ret+= [1,4].pack("CC")
					ret+= tmp2.pack("CCCC")
				when :router
					tmp = key[1].split('.')
					tmp2 =[]
					tmp.each do |c| tmp2.push c.to_i end
					ret+= [3,4].pack("CC")
					ret+= tmp2.pack("CCCC")	
				when :lease_time
					ret+= [51,4,key[1]].pack("CCN")
				when :dhcp_server
					tmp = key[1].split('.')
					tmp2 =[]
					tmp.each do |c| tmp2.push c.to_i end
					ret+= [54,4].pack("CC")
					ret+= tmp2.pack("CCCC")	
				when :dns_server
					tmp = key[1].split('.')
					tmp2 =[]
					tmp.each do |c| tmp2.push c.to_i end
					ret+= [6,4].pack("CC")
					ret+= tmp2.pack("CCCC")	
				else putlog "FATAL! You forgot to add support for: " + key[0].to_s
			end
		end
		ret
	end
end


#Message types
# http://www.iana.org/assignments/bootp-dhcp-parameters
DHCPDISCOVER = 1
DHCPOFFER=2
DHCPREQUEST=3
DHCPDECLINE=4
DHCPACK=5
DHCPNAK=6
DHCPRELEASE=7
DHCPINFORM=8
DHCPFORCERENEW=9
DHCPLEASEQUERY=10
DHCPLEASEUNASSIGNED=11
DHCPLEASEUNKNOWN=12
DHCPLEASEACTIVE=13

# other settings.
hport = 67
cport = 68
MAXRECVLEN  = 1500
# program start.
require 'socket'
soc = UDPSocket.new
soc.setsockopt( Socket::SOL_SOCKET, Socket::SO_REUSEADDR, 1 ) 
putlog "binding on #{interface}"
soc.bind(interface,hport)
loop do
	data,meta = soc.recvfrom(MAXRECVLEN)
	packet = BootpPacket.new
	packet.parse(data)
	case packet.options[:message_type]
	when DHCPDISCOVER	
		putlog "Got DHCP-Discover from " + packet.macf + "/"+  packet.options[:hostname].to_s
		
		reply = packet.clone
		reply.op = 2
		#if packet.options[:address_request] != nil
		lease = [network[0],network[1],network[2],giveIpTo(packet.macf)]		
		reply.yiaddr = lease.pack("CCCC").unpack("N")[0]
		reply.options = {:message_type=>DHCPOFFER}
		reply.options[:subnet_mask] =  mask
		reply.options[:router] = gateway
		reply.options[:lease_time] = leasetime
		reply.options[:dhcp_server] = interface
		reply.options[:dns_server] = dns 
		soc.send(reply.toPacket, 0, broadcast, cport)
		putlog "Sending Offer " + lease.join(".") 
	when DHCPREQUEST
		putlog "Got request."		
		reply = packet.clone
		reply.op = 2		
		lease = [network[0],network[1],network[2],whois(packet.macf)]
		if lease[3] == nil
			putlog "Got DHCPRequest but the owner is missing in the database"
			break
		end
		reply.yiaddr = lease.pack("CCCC").unpack("N")[0]
		reply.options = {:message_type=>DHCPACK}
		reply.options[:subnet_mask] =  mask
		reply.options[:router] = gateway
		reply.options[:lease_time] = leasetime
		reply.options[:dhcp_server] = interface		
		reply.options[:dns_server] = dns 
		soc.send(reply.toPacket, 0, broadcast, cport)
		putlog "ACK sent."
	when DHCPRELEASE
		if @staticdb.member?(packet.macf)
			putlog "Got release from " + packet.macf + ", ignored! You're in the static database."		
		else
			n = whois(packet.macf)
			if n != nil
				@database[n] = nil			
				putlog "Got release from " + packet.macf + ", freeing up " + n.to_s + "!"
			else
				putlog "Got release from " + packet.macf + ", ignored! Not in the database."
			end
		end
	when nil
		putlog "PANIC! Packet Has no message_type"
	else
        putlog "PANIC! Unknown message type "+ packet.options[:message_type].inspect
	end
end
