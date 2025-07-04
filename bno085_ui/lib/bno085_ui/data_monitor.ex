defmodule Bno085Ui.DataMonitor do
  use GenServer
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

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], [])
  end

  @impl true
  def init(_opts) do
    Phoenix.PubSub.subscribe(:my_pubsub, "accelerometer")
    {:ok, %{}}
  end

  @impl true
  def handle_info(msg, state) do
    # Logger.info("I'm receiving it #{inspect(msg)}")

    {:noreply, state}
  end

  # [{~U[2025-01-21 15:51:03.989031Z], %{z: 9.4609375, y: -0.57421875, x: -0.84375}}, {~U[2025-01-21 15:51:03.029996Z], %{z: 9.4609375, y: -0.57421875, x: -0.84375}}, {~U[2025-01-21 15:51:02.071208Z], %{z: 9.5, y: -0.57421875, x: -0.8828125}}]
end
