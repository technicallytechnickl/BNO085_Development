import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :bno085_ui, Bno085UIWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "vchlUNjVzRhky4vi+apPvCSzzCbZZLCdTK+dPu4N0JybjHwfC8Pnml7dQnfJCpPp",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
