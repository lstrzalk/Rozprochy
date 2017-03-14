require 'socket'
require 'ipaddr'
require 'thread'
require_relative 'messenge'
class Client
	def initialize(server, nickname)
		@server = server
		@nickname = nickname
		@id = -1
		@request = nil
		@responseTCP = nil
		@responseUDP = nil
		@udpMulticast = nil
		@semaphore = Mutex.new
		@messenge = Messenge.new(@id,@nickname)
		@udpSocket = UDPSocket.new
		@udpMulticastSender = nil
		@udpMulticastSocket = nil
		@@MULTICAST_ADDR = "228.5.6.7"
		@@BIND_ADDR = "0.0.0.0"
		@@PORT = 9998
		connect
		listenTCP
		listenUDP
		listenUDPMulticast
		send
		@request.join
		@responseTCP.join
		@responseTCP.join
		@udpMulticast.join
	end
	def connect
		tryTimes = 0
		maxTrys = 5
		while @id == -1 do
			@server.puts(@messenge.encode('Getting ID',0))
			res = @messenge.decode(@server.gets.chomp)
			if(res[:flag].to_i == 0)
				@id = res[:body].to_i
				@messenge.setID(@id)
				@udpSocket.bind('localhost',@id)
				@udpSocket.connect('localhost',3000)
				ip = IPAddr.new(@@MULTICAST_ADDR).hton+IPAddr.new(@@BIND_ADDR).hton
				#@udpMulticastSocket = UDPSocket.new
				@udpMulticastSocket ||= UDPSocket.open.tap do |socket|
      				socket.setsockopt(:IPPROTO_IP, :IP_ADD_MEMBERSHIP, ip)
      				socket.setsockopt(:IPPROTO_IP, :IP_MULTICAST_TTL, true)
      				socket.setsockopt(:SOL_SOCKET, :SO_REUSEPORT, true)
    			end
				@udpMulticastSocket.bind(@@BIND_ADDR, @@PORT)
				puts "succesfully connected #{@nickname} with id #{@id}"
			else
				if(tryTimes>maxTrys)
					@server.puts(@messenge.encode("connection refused",-4))
					@udpSocket.close
					puts "Sorry"
					abort
				end
				puts res[:body]
				sleep(5)
				tryTimes = tryTimes + 1
			end
		end
	end
	def listenTCP
		@responseTCP = Thread.new do
			loop do
				msg = @messenge.decode(@server.gets.chomp)
				print "\r"
				(@nickname.length + 3).times do
					print " "
				end
				puts "\r@#{msg[:nickname]}/> #{msg[:body]}"
				print "@#{@nickname}/> "
			end
		end
	end
	def listenUDP
		@responseUDP = Thread.new do
			loop do
				data, client = @udpSocket.recvfrom(1024)
				msg = @messenge.decode(data)
				printMessenge(msg)
			end
		end
	end
	def listenUDPMulticast
		@udpMulticast = Thread.new do
			loop do
				data, client = @udpMulticastSocket.recvfrom(1024)
				msg = @messenge.decode(data)
				unless msg[:id].to_i == @id
					printMessenge(msg)
				end
			end
		end
	end
	def send
		@request = Thread.new do
			loop do
			    print "@#{@nickname}/> "
			    msg = $stdin.gets.chomp
				if /^-[M-O]/ =~ msg
					if /^-r/ =~ msg.split(/^-[M-O]\s/)[1]
						msg = readFile(msg)
					end
					if msg.kind_of?(Array)
						if /^-O/ =~ msg[0]
							msg.each do |art|
								@udpMulticastSocket.send(@messenge.encode(art,1), 0, @@MULTICAST_ADDR, @@PORT)
							end
						else
							msg.each do |art|
								@udpSocket.send(@messenge.encode(art,1),0)
							end
						end
					else
						if /^-O/ =~ msg
							@udpMulticastSocket.send(@messenge.encode(msg,1), 0, @@MULTICAST_ADDR, @@PORT)
						else
							@udpSocket.send(@messenge.encode(msg,1),0)
						end
					end
			    elsif /^-H/ =~ msg
			    	puts help
			    else
			    	@server.puts( @messenge.encode(msg,1))
			    end
			end
		end
	end
	def help
		return "-M messange text => Sending UDP to all Users\n"+
				"-N -user1 -user2 ... -userN \# messenge text => Sending UDP to selected Users\n"+
				"-O messenge text => Sending UDP Mutlicast\n"+
				"-[M-O] -r filename => Sending file to Users as above\n"+
				"text messenge => Sending TCP to all Users"
	end
	def readFile(name)
        splitted = name.split(/\s-r\s/)
		begin
			art = IO.readlines(splitted[1])
			art.map! do |x|
				x = "#{splitted[0]} #{x}"
			end
			return art
		rescue
			puts "File not found!"
			return -1
		end
	end
	def printMessenge(msg)
		@semaphore.synchronize do
			print "\r"
			(@nickname.length + 3).times do
				print " "
			end
			printable = msg[:body]
			if  /^-[M|O]/=~ printable 
				puts "\r@#{msg[:nickname]}/> #{printable.split(/^-[M|O]\s/)[1]}"
			elsif /^-N(\s-\w+)+\s+#\s+/ =~ printable
				puts "\r@#{msg[:nickname]}/> #{printable.split(/^-N(\s-\w+)+\s+#\s+/)[2]}"
			else
				puts "\r@#{msg[:nickname]}/> #{printable}"
			end
			print "@#{@nickname}/> "
		end
	end
end
