defmodule Bno085UI.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Bno085UIWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:bno085_ui, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Bno085UI.PubSub},
      # Start a worker by calling: Bno085UI.Worker.start_link(arg)
      # {Bno085UI.Worker, arg},
      # Start to serve requests, typically the last entry
      Bno085UIWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bno085UI.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    Bno085UIWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
