# defmodule Doctor do
#   @exchange "medical"
#   def orderTest do
#     {:ok, connection} = AMQP.Connection.open
#     {:ok, channel} = AMQP.Channel.open(connection)

#     if length(System.argv) != 2 do
#       IO.puts "Usage: mix run doctor.exs [test case] [doctors name]"
#       System.halt(1)
#     end
#     IO.puts is_list System.argv
#     {topic, message} = System.argv |> &([&1|&2] -> {&1, Enum.join(&2, " ")})
#     AMQP.Exchange.declare(channel, @exchange, :topic)

#     AMQP.Basic.publish(channel, @exchange, topic, message)
#     IO.puts " [x] Sent '[#{topic}] #{message}'"
#     Doctor.getResult(channel, connection)
#   end
#   def getResult(channel, connection) do
#       receive do
#         {:basic_deliver, payload, meta} ->
#         IO.puts " [x] Received [#{meta.routing_key}] #{payload}"
#         AMQP.Connection.close(connection)
#     end
#   end 
# end
# 
# Doctor.orderTest
IO.puts is_list System.argv









