# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :naiveticketapp,
  ecto_repos: [Naiveticketapp.Repo]

# Configures the endpoint
config :naiveticketapp, NaiveticketappWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "x7mGR0NVHp0CamUOQ8DGtv2z4VI03S2svSh4PIl/l1GhiQ7NEwrz2ERJhk7i1ECe",
  render_errors: [view: NaiveticketappWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Naiveticketapp.PubSub, adapter: Phoenix.PubSub.PG2]

config :naiveticketapp,
  stripe_publishable_key: "pk_test_9tcooplWeOsEckpEt2xNQSSo005cRWiWTn"

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
