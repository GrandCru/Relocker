Relocker
========

A library for holding a lock in redis. The locking algorithm is the one described on
http://redis.io/topics/distlock as "Correct implementation with a single instance".


Usage
=====

Easiest way to keep a lock is to start either a `Relocker.Server` or `Relocker.Fsm` process with a
registered name. When the process exits the lock will be freed.

For example:

```elixir
defmodule Game do
  use Relocker.Server

  def init(opts) do
    super(opts)
    {:ok, %{}}
  end

  # some meaningful code here

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def terminate(reason, state) do
    super(reason, state)
  end
end
```

This will create a lock with name "player_1"
```elixir
iex> {:ok, pid} = Game.start_link([], name: "player_1")
```

If you try to start a new one while the old one is running you get:
```elixir
iex> {:error, {:already_started, ...}} = Game.start_link [], name: "player_1"
```

When a process has been registered, you can send messages via registry just by using the lock name
```elixir
iex> GenServer.cast({:via, Relocker.Registry, "player_1"}, :stop)
```

Configure Redis
===============

You need to give the library a connection string in the application config:

```elixir
# config.exs

config :relocker,
  locker: Relocker.Locker.Redis,
  redis: "redis://192.168.33.11:6379"

```

Or if you want to use a connection pool with Redis:

```elixir
# config.exs

config :relocker,
  locker: Relocker.Locker.Pool,
  redis: "redis://192.168.33.11:6379",
  pool: [
    size: 5
  ]

```

The `pool` options are directly fed to [poolboy](https://github.com/devinus/poolboy). If you omit `pool` from config the library
will use this default config:

```elixir
[
  name: { :local, Relocker.Locker.Pool },
  worker_module: Relocker.Locker.Pool,
  size: 5,
  max_overflow: 10
]
```

License notice
==============

Parts of the codebase like `lib/server.ex` and `lib/fsm.ex` heavily borrow from this
project: https://github.com/tsharju/elixir_locker.

All other code (c) Grand Cru. See `LICENSE` for details.

