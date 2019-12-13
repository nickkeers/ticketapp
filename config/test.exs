use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :naiveticketapp, NaiveticketappWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :naiveticketapp, Naiveticketapp.Repo,
  username: "postgres",
  password: "postgres",
  database: "naiveticketapp_test",
  hostname: System.get_env("DB_HOST", "localhost"),
  pool: Ecto.Adapters.SQL.Sandbox
