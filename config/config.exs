use Mix.Config

config :relocker,
  locker: Relocker.Locker.Agent,
  redis: "redis://192.168.33.11:6379",
  pool: [
    name: { :local, Relocker.Locker.Pool },
    worker_module: Relocker.Locker.Pool,
    size: 5,
    max_overflow: 10
  ]

import_config "#{Mix.env}.exs"