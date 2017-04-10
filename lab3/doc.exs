defmodule Doctor do
  @exchange "cccp"
  @queue "results"
  @fanoutExchange "fanout"

  def configure do
    {:ok, connection} = AMQP.Connection.open
    {:ok, channel} = AMQP.Channel.open(connection)

    if length(System.argv) != 3 do
      IO.puts "Usage: mix run doctor.exs [doctor] [examination] [patient]"
      System.halt(1)
    end
    [doctor, examination, patient] = System.argv

    channel |> AMQP.Exchange.declare(@exchange, :topic)
    channel |> AMQP.Exchange.declare(@fanoutExchange, :fanout)

    {:ok, %{queue: queue_name}} = AMQP.Queue.declare(channel, "", exclusive: true)
    {:ok, %{queue: queue_fanout_name}} = AMQP.Queue.declare(channel, "", exclusive: true)

    channel |> AMQP.Queue.bind(queue_name, @exchange, routing_key: "doctor.#{doctor}")
    channel |> AMQP.Basic.consume(queue_name, nil, no_ack: true)

    channel |> AMQP.Queue.bind(queue_fanout_name, @fanoutExchange)
    channel |> AMQP.Basic.consume(queue_fanout_name, nil, no_ack: true)
    pid = spawn(fn -> Doctor.orderTest(channel,doctor, examination, patient) end)
    pid |> Doctor.getResult
  end

  def orderTest(channel, doctor, examination, patient) do
    channel |> AMQP.Basic.publish(@exchange, Enum.join([examination, doctor], "."), patient)
    IO.puts " [x] Sent 'Destination #{Enum.join([examination, doctor], ".")}, #{patient}'"
    receive do
      {:ok, "confirm"} -> :timer.sleep(5000)
    end
    channel |> Doctor.orderTest(doctor, examination, patient)
  end
  def getResult(pid) do
    receive do
        {:basic_deliver, payload, meta} ->
        if String.match?(meta.routing_key,~r/\w+.\w+/) do
          IO.puts " [x] Received from #{meta.routing_key} #{payload}"
          send pid, {:ok, "confirm"}
        else
          IO.puts " [x] Received from admin: #{payload}"
        end
        pid|> Doctor.getResult()
    end
  end
end

Doctor.configure





