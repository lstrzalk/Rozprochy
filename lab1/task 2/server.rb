require 'socket'
require_relative 'messenge'

class Server
	def initialize(port, ip)
		@host = "localhost"
		@messenge = Messenge.new(0,'Server')
		@server = TCPServer.open(ip,port)
		@clients = Hash.new
		@udpSocket = UDPSocket.new
		@udpSocket.bind(ip, port)
		@udpList = nil
		@tcpList = nil
		@clients = Hash.new
		@udpClients = Hash.new
		@lastGivenId = 0
		@maxHostsAmount = 2
		@actualHostsAmount = 0
		run
		@udpList.join
		@tcpList.join
	end

	def run
		loop {
			#Thread.start(@server.accept) do |client|
				client = @server.accept
				kill = false
				loop do
					req = @messenge.decode(client.gets.chomp)
					if req[:flag].to_i == 0
						if !@clients[req[:nickname].to_sym] and @actualHostsAmount <= @maxHostsAmount
							kill = true
							@lastGivenId = @lastGivenId + 1
							@udpClients[req[:nickname].to_sym] = req[:body].to_i
							@clients[req[:nickname].to_sym] = client
							@actualHostsAmount = @actualHostsAmount + 1
							puts "#{req[:nickname]} is registered with id #{@lastGivenId}"
							client.puts @messenge.encode(@lastGivenId.to_s,0)
							listen_UDPmessenges(req[:nickname].to_sym, client)
							listen_TCPmessenges(req[:nickname].to_sym, client)
						else
							if @actualHostsAmount > @maxHostsAmount
								client.puts @messenge.encode('Number of users exceeded',-2)
							else
								client.puts @messenge.encode('Nickname already in use',-3)
							end
						end
					end
					break if req[:flag].to_i == -4 or kill
				end
			#end
		}.join
	end

	def listen_UDPmessenges(nickname, client)
		@udpList = Thread.new do
			loop do
				data, client = @udpSocket.recvfrom(1024)
				decoded = @messenge.decode(data)
				msg = decoded[:body]
				if /^-M/ =~ msg 
					broadcast(data, @udpClients)
				elsif /^-N/ =~ msg
					multicast(data, @udpClients)
				end
			end
		end
	end

	def listen_TCPmessenges(nickname, client)
		@tcpList = Thread.new do
			loop do
				msg = client.gets.chomp
				puts msg
				@clients.each do |key, value|
					unless key == nickname
						value.puts msg
					end
				end
			end
		end
	end
	def broadcast(data, clients)
		decoded = @messenge.decode(data)
		clients.each do |nickname, client|
			unless decoded[:nickname] == nickname.to_s
				@udpSocket.send(data, 0, @host, client)
			end
		end
	end
	def multicast(data, clients)
		decoded = @messenge.decode(data)
		multicastClients = decoded[:body].split(/-N/)[1].split(/\s#\s/)[0].split(/\s\-/)
		newClients = Hash.new
		for i in 1..(multicastClients.length-1)
			if clients[multicastClients[i].to_sym]
				newClients[multicastClients[i].to_sym] = @udpClients[multicastClients[i].to_sym]
			end
		end
		broadcast(data, newClients)
	end
end
Server.new(3000, "localhost")
