defmodule ExChange.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ExChange.Repo,
      # Start the Telemetry supervisor
      ExChangeWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ExChange.PubSub},
      # Start the Endpoint (http/https)
      ExChangeWeb.Endpoint,
      # Start a worker by calling: ExChange.Worker.start_link(arg)
      {Absinthe.Subscription, ExChangeWeb.Endpoint},
      {Registry, keys: :unique, name: ExChange.Registry},
      ExChange.RatesServer.Superviser
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExChange.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExChangeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
