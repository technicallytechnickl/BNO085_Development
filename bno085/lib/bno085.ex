defmodule Bno085 do
  @moduledoc File.read!("README.md")
             |> String.split("# Usage")
             |> Enum.fetch!(1)

  @behaviour :gen_statem
  def callback_mode, do: :state_functions

  @name :bno085_statem

  alias Circuits.I2C
  alias Circuits.GPIO

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
    IO.inspect(name, label: "Name: ")
    IO.inspect(__MODULE__, label: "Module: ")
    :gen_statem.start_link({:global, name}, __MODULE__, [], [])
  end

  # Mandatory Callbacks
  def init([]) do
    {:ok, :idle, []}
  end

  def terminate(reason, _state, _data) do
    IO.inspect("#{@name} terminated with reason:")
    IO.inspect(reason, label: "Reason")
  end

  # State Callbacks
  # :gen_statem.call({:global, :bno085_proc}, :initialize)
  def idle({:call, from}, :initialize, data) do
    case GenServer.start_link(Shtp.Shtp, [], name: :bno085_shtp) do
      {:ok, pid} ->
        {:next_state, :connected, %{pid: pid}, [{:reply, from, :connected}]}

      _ ->
        {:keep_state, data, [{:reply, from, :idle}]}
    end
  end

  def connected({:call, from}, _anything, data) do
    IO.inspect("OK")
    {:keep_state, data, [{:reply, from, :ok}]}
  end
end
