# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :ex_change,
  ecto_repos: [ExChange.Repo]

# Configures the endpoint
config :ex_change, ExChangeWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ExChangeWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: ExChange.PubSub,
  live_view: [signing_salt: "L+ZqxAY8"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configures Ecto Shorts https://hexdocs.pm/ecto_shorts/EctoShorts.html
config :ecto_shorts,
  repo: ExChange.Repo,
  error_module: EctoShorts.Actions.Error

config :ex_change,
  alphavantage_api_key: System.get_env("ALPHAVANTAGE_API_KEY")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
