defmodule Admin do
  @exchange "cccp"
  @fanoutExchange "fanout"
  @queue "listen"

  def configure do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)

    channel |> AMQP.Exchange.declare(@exchange, :topic)

    {:ok, %{queue: queue_name}} = AMQP.Queue.declare(channel, @queue)

    channel |> AMQP.Queue.bind(queue_name, @exchange, routing_key: "#")
    channel |> AMQP.Basic.consume(queue_name, nil, no_ack: true)
    Task.async(fn -> Admin.send(channel) end)
    Admin.listen
    
  end

  def listen() do
    receive do
        {:basic_deliver, payload, meta} ->
        IO.puts " [x] Received from #{meta.routing_key}: #{payload}"
        Admin.listen
    end
  end

  def send(channel) do
    channel |> AMQP.Basic.publish(@fanoutExchange, "", IO.gets "#>")
    channel |> Admin.send
  end
end

Admin.configure





