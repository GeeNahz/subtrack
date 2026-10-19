defmodule Subtrack.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SubtrackWeb.Telemetry,
      Subtrack.Repo,
      {Oban, Application.fetch_env!(:subtrack, Oban)},
      {DNSCluster, query: Application.get_env(:subtrack, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Subtrack.PubSub},
      # Start a worker by calling: Subtrack.Worker.start_link(arg)
      # {Subtrack.Worker, arg},
      # Start to serve requests, typically the last entry
      SubtrackWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Subtrack.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SubtrackWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
