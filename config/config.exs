use Mix.Config

config :lager,
  log_root: '/tmp',
  handlers: []

config :logger, handle_otp_reports: false

config :logger, :console,
  format: "$message\n",
  level: :info
