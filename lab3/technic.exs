defmodule Technic do
  @exchange "cccp"
  @fanoutExchange "fanout"


  def configure do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)

    AMQP.Exchange.declare(channel, @exchange, :topic)
    if length(System.argv) != 2 do
      IO.puts "Usage: mix run receive_logs_topic.exs [binding_key]..."
      System.halt(1)
    end

    for binding_key <- System.argv do
      {:ok, %{queue: queue_name}} = AMQP.Queue.declare(channel, String.split(binding_key, ".") |> hd)
      channel |> AMQP.Queue.bind(queue_name, @exchange, routing_key: binding_key)
      channel |> AMQP.Basic.consume(queue_name, nil, no_ack: true)
    end
    channel |> AMQP.Exchange.declare(@fanoutExchange, :fanout)
    {:ok, %{queue: queue_fanout_name}} = AMQP.Queue.declare(channel, "", exclusive: true)
    channel |> AMQP.Queue.bind(queue_fanout_name, @fanoutExchange)
    channel |> AMQP.Basic.consume(queue_fanout_name, nil, no_ack: true)
    IO.puts " [*] Waiting for messages. To exist press CTRL+C, CTRL+C"
    channel |> Technic.wait_for_messages
  end

  def wait_for_messages(channel) do
    receive do
      {:basic_deliver, payload, meta} ->
        if String.match?(meta.routing_key,~r/\w+.\w+/) do
          IO.puts " [x] Received from #{meta.routing_key} #{payload}"
          channel |> Technic.send_response(String.split(meta.routing_key, ~r/\./) |> tl |> List.to_string, payload)
        else
          IO.puts " [x] Received from admin: #{payload}"
        end
        channel |> wait_for_messages
    end
  end
  def send_response(channel, doctor, payload) do
    channel |> AMQP.Basic.publish(@exchange, "doctor.#{doctor}", "examination of #{payload}")
    IO.puts " [x] Sent to doctor.#{doctor}"
  end
end
  
Technic.configure
