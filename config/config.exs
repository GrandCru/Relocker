use Mix.Config

config :relocker,
  locker: Relocker.Locker.Agent,
  pool: [
    name: { :local, Relocker.Locker.Pool },
    worker_module: Relocker.Locker.Pool,
    size: 5,
    max_overflow: 10
  ]