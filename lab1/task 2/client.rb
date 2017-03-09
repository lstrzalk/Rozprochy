require 'socket'
require_relative 'messenge'
class Client
	def initialize(server, nickname)
		@server = server
		@nickname = nickname
		@id = -1
		@request = nil
		@responseTCP = nil
		@responseUDP = nil
		@messenge = Messenge.new(@id,@nickname)
		@udpSocket = UDPSocket.new
		connect
		listenTCP
		listenUDP
		send
		@request.join
		@responseTCP.join
		@responseTCP.join
	end
	def connect
		tryTimes = 0
		maxTrys = 5
		@udpSocket.connect('localhost',3000)
		while @id == -1 do
			@server.puts(@messenge.encode(@udpSocket.addr[1],0))
			res = @messenge.decode(@server.gets.chomp)
			if(res[:flag].to_i == 0)
				@id = res[:body].to_i
				@messenge.setID(@id)
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
				print "\r"
				(@nickname.length + 3).times do
					print " "
				end
				printable = msg[:body]
				if  /^-M/=~ printable 
					puts "\r@#{msg[:nickname]}/> #{printable.split(/^-M\s*/)[1]}"
				elsif /^-N(\s-\w+)+\s+#\s+/ =~ printable
					puts "\r@#{msg[:nickname]}/> #{printable.split(/^-N(\s-\w+)+\s+#\s+/)[2]}"
				else
					puts "\r@#{msg[:nickname]}/> #{printable}"
				end
				print "@#{@nickname}/> "
			end
		end
	end
	def send
		@request = Thread.new do
			loop do
			    print "@#{@nickname}/> "
			    msg = $stdin.gets.chomp
			    if /^-M/ =~ msg or /^-N/ =~ msg
			    	@udpSocket.send(@messenge.encode(msg,1),0)
			    elsif /^-H/ =~ msg
			    	puts help
			    else
			    	@server.puts( @messenge.encode(msg,1))
			    end
			end
		end
	end
	def help
		return "-M messange text => Sending UDP Broadcast\n-N -user1 -user2 ... -userN \# messenge text => Sending UDP Multicast\ntext messenge => Sending TCP Broadcast"
	end
end
