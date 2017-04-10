defmodule Technic do
  @exchange "cccp"

  def start do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)

    AMQP.Exchange.declare(channel, @exchange, :topic)

    if length(System.argv) == 0 do
      IO.puts "Usage: mix run receive_logs_topic.exs [binding_key]..."
      System.halt(1)
    end
    for binding_key <- System.argv do
      IO.puts binding_key
      IO.puts String.split(binding_key, ".") |> hd
      {:ok, %{queue: queue_name}} = AMQP.Queue.declare(channel, String.split(binding_key, ".") |> hd)
      AMQP.Queue.bind(channel, queue_name, @exchange, routing_key: binding_key)
      AMQP.Basic.consume(channel, queue_name, nil, no_ack: true)
    end


    IO.puts " [*] Waiting for messages. To exist press CTRL+C, CTRL+C"

    Technic.wait_for_messages(channel)
  end

  def wait_for_messages(channel) do
    receive do
      {:basic_deliver, payload, meta} ->
        IO.puts " [x] Received [#{meta.routing_key}] #{payload}"
        wait_for_messages(channel)
    end
  end
end
  
Technic.start
