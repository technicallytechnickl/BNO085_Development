defmodule Bno085 do
  @moduledoc File.read!("README.md")
             |> String.split("# Usage")
             |> Enum.fetch!(1)

  @behaviour :gen_statem
  def callback_mode, do: :state_functions

  @name :bno085_statem

  alias Circuits.I2C
  alias Circuits.GPIO
  alias Phoenix.PubSub

  require Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  # API

  def start_link([name: name] \\ []) do
    IO.inspect("Start_Link")
    IO.inspect(name, label: "Name: ")
    IO.inspect(__MODULE__, label: "Module: ")
    :gen_statem.start_link({:global, name}, __MODULE__, [], [])
  end

  # Mandatory Callbacks
  def init([]) do
    IO.inspect("init")

    {:ok, :idle, %{}}
  end

  def terminate(reason, _state, _data) do
    IO.inspect("#{@name} terminated with reason:")
    IO.inspect(reason, label: "Reason")
  end

  # State Callbacks
  # :gen_statem.call({:global, :bno085_proc}, :initialize)
  def idle({:call, from}, :initialize, data) do
    result =
      case GenServer.start(Shtp.Shtp, [], []) do
        {:ok, pid} ->
          IO.inspect("going to connected")

          {:next_state, :connected, %{pid: pid}, [{:reply, from, :connected}]}

        _ ->
          {:keep_state, data, [{:reply, from, :idle}]}
      end

    # {pid, reference} = GenServer.start(Shtp.Shtp, [], [])
    # IO.inspect(pid, label: "PID: ")
    # {:next_state, :connected, %{pid: pid, reference: reference}, [{:reply, from, "I replied"}]}
  end

  def connected({:call, from}, {:start_sampling, sensor}, data) do
    IO.inspect(data, label: "Data: ")
    IO.inspect("starting sample")
    %{pid: pid} = data
    result = GenServer.call(pid, {:start, sensor, 1_000_000})
    data = Map.put(data, sensor, [])
    {:next_state, :sampling, data, [{:reply, from, {:ok, result}}]}
  end

  def sampling(:cast, {:accelerometer, values}, %{accelerometer: buffer} = data) do
    data =
      values
      |> IO.inspect(label: "I'm sampling here")
      |> increment_buffer(buffer)
      |> publish_buffer(:accelerometer)
      |> update_state(:accelerometer, data)

    # |> IO.inspect(label: "State:")

    {:keep_state, data}
  end

  def sampling(:cast, :read, %{pid: pid} = data) do
    GenServer.cast(pid, :read)
    {:keep_state, data}
  end

  defp increment_buffer(value, buffer) do
    # hardcoded buffer length of 10
    buffer_len = 10

    if length(buffer) < buffer_len do
      [{DateTime.utc_now(), value} | buffer]
    else
      [{DateTime.utc_now(), value} | List.delete_at(buffer, -1)]
    end
  end

  defp publish_buffer(buffer, topic) do
    PubSub.broadcast(:my_pubsub, Atom.to_string(topic), buffer)
    buffer
  end

  defp update_state(value, key, state) do
    Map.replace(state, key, value)
  end
end
