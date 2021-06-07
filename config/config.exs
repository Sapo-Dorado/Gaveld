# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :gaveld,
  ecto_repos: [Gaveld.Repo]

# Configures the endpoint
config :gaveld, GaveldWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "YGZXQuM2SYLuiFWzlB8GAEOBX3g/DnW+3oOdT6yUq1HBCALZt8ghJ7tqDndck/zs",
  render_errors: [view: GaveldWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: Gaveld.PubSub,
  live_view: [signing_salt: "gf73Yg8c"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
