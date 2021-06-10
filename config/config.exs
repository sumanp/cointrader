# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :cointrader, CointraderWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "l2gaAMVvJot3benNtmU0NCoYuLQwxP4YzdpFGT5yEj6G6YcGrngEpK64yXY40fmZ",
  render_errors: [view: CointraderWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Cointrader.PubSub,
  live_view: [signing_salt: "r+KxvXnc"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :elixir, :time_zone_database, Tzdata.TimeZoneDatabase
# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
