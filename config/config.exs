use Mix.Config

config :relocker,
  locker: Relocker.Locker.Agent,
  pool: [
    name: { :local, Relocker.Locker },
    worker_module: Relocker.Locker.Pool,
    size: 10,
    max_overflow: 0
  ]