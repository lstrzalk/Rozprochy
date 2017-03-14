require_relative 'client'

server = TCPSocket.open( "localhost", 3000 )
c = Client.new(server, 'Trocki');