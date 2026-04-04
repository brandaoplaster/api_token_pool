defmodule ApiTokenPool.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ApiTokenPoolWeb.Telemetry,
      ApiTokenPool.Repo,
      {DNSCluster, query: Application.get_env(:api_token_pool, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: ApiTokenPool.PubSub},
      # Start a worker by calling: ApiTokenPool.Worker.start_link(arg)
      # {ApiTokenPool.Worker, arg},
      # Start to serve requests, typically the last entry
      ApiTokenPoolWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ApiTokenPool.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ApiTokenPoolWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
