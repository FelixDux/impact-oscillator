# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of the Config module.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

config :imposc_ui,
  generators: [context_app: false]

# Configures the endpoint
config :imposc_ui, ImposcUi.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "SX+VeCPRWJeVJirZ7INIkvU0Zq+26F6E1HfuWznPB7rl5BK7nExk1+I7CDOgkLYl",
  render_errors: [view: ImposcUi.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ImposcUi.PubSub,
  live_view: [signing_salt: "6+yB/wjF"]

# Sample configuration:
#
#     config :logger, :console,
#       level: :info,
#       format: "$date $time [$level] $metadata$message\n",
#       metadata: [:user_id]
#

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
