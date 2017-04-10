defmodule Doctor do
  @exchange "medical"
  def orderTest do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)
    IO.puts length(System.argv)
    if length(System.argv) != 3 do
      IO.puts "Usage: mix run doctor.exs [test case] [doctors name]"
      System.halt(1)
    end
    IO.puts System.argv
    [topic | message] = System.argv
    AMQP.Exchange.declare(channel, @exchange, :topic)

    AMQP.Basic.publish(channel, @exchange, topic, message)
    IO.puts " [x] Sent '[#{topic}] #{message}'"
    Doctor.getResult(channel, connection)
  end
  def getResult(channel, connection) do
      receive do
        {:basic_deliver, payload, meta} ->
        IO.puts " [x] Received [#{meta.routing_key}] #{payload}"
        AMQP.Connection.close(connection)
    end
  end 
end

Doctor.orderTest









