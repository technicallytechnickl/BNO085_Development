defmodule Bno085Manager do
  @behaviour GenServer

  import Logger

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker,
      restart: :permanent,
      shutdown: 5000
    }
  end

  def start_link([name: name] \\ []) do
    GenServer.start_link(__MODULE__, [], name: :"__MODULE__:#{name}")
  end

  @impl GenServer
  def init(_opts) do
    {:ok, %{}, {:continue, :startup}}
  end

  @impl true
  def handle_continue(:startup, state) do
    Process.sleep(5000)
    GenServer.call({:global, :bno085_proc}, :initialize)
    Process.sleep(5000)
    GenServer.call({:global, :bno085_proc}, {:start_sampling, :accelerometer})
    Phoenix.PubSub.subscribe(:my_pubsub, "accelerometer")
    IO.inspect("STARTED!!!")
    {:noreply, state, 500}
  end

  def handle_info(:timeout, state) do
    IO.inspect("ALIVE")
    Logger.info("ALIVE LOGGER")
    {:noreply, state, 500}
  end

  @impl true
  def handle_info(msg, state) do
    IO.inspect({"I'm receiving it", msg})
    Logger.info("I'm receiving it LOGGER")
    {:noreply, state, 500}
  end
end
