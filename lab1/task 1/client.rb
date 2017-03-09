require 'socket'
require_relative 'messenge'
class Client
	def initialize(server, nickname)
		@server = server
		@nickname = nickname
		@id = -1
		@request = nil
		@response = nil
		@messenge = Messenge.new(@id,@nickname)
		connect
		listen
		send
		@request.join
		@response.join
	end
	def connect
		tryTimes = 0
		maxTrys = 5
		while @id == -1 do
			@server.puts(@messenge.encode("id request",0))
			res = @messenge.decode(@server.gets.chomp)
			if(res[:flag].to_i == 0)
				@id = res[:body].to_i
				@messenge.setID(@id)
				#@server.puts(@messenge.encode("id accepted",-4))
				puts "succesfully connected #{@nickname} with id #{@id}"
			else
				if(tryTimes>maxTrys)
					@server.puts(@messenge.encode("connection refused",-4))
					puts "Sorry"
					abort
				end
				puts res[:body]
				sleep(5)
				tryTimes = tryTimes + 1
			end
		end
	end
	def listen
		@response = Thread.new do
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
	def send
		@request = Thread.new do
			loop do
			    print "@#{@nickname}/> "
			    msg = $stdin.gets.chomp
			    @server.puts( @messenge.encode(msg,1))
			end
		end

	end
end
