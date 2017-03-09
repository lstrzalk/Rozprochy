require 'socket'
require_relative 'messenge'

class Server
	def initialize(port, ip)
		@messenge = Messenge.new(0,'Server')
		@server = TCPServer.open(ip,port)
		@clients = Hash.new
		@lastGivenId = 0
		@maxHostsAmount = 2
		@actualHostsAmount = 0
		run
	end

	def run
		loop {
			Thread.start(@server.accept) do |client|
				kill = false
				loop do
					req = @messenge.decode(client.gets.chomp)
					if req[:flag].to_i == 0
						if !@clients[req[:nickname].to_sym] and @actualHostsAmount <= @maxHostsAmount
							kill = true
							@lastGivenId = @lastGivenId + 1
							@clients[req[:nickname].to_sym] = client
							@actualHostsAmount = @actualHostsAmount + 1
							puts "#{req[:nickname]} is registered with id #{@lastGivenId}"
							client.puts @messenge.encode(@lastGivenId.to_s,0)
							listen_messeges(req[:nickname].to_sym, client)
						else
							puts req
							if @actualHostsAmount > @maxHostsAmount
								client.puts @messenge.encode('Number of users exceeded',-2)
							else
								client.puts @messenge.encode('Nickname already in use',-3)
							end
						end
					end
					break if req[:flag].to_i == -4 or kill
				end
			end
		}.join
	end

	def listen_messeges(nickname, client)
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
Server.new(3000, "localhost")
