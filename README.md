Relocker
========

A library for holding a lock in redis.

Usage
=====

Easiest way to keep a lock is to start either a `Relocker.Server` or `Relocker.Fsm` process with a 
registered name. When the process exits the lock will be freed.

For example:

```
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
```
iex> {:ok, pid} = Game.start_link([], name: "player_1")
```

If you try to start a new one while the old one is running you get: 
```
iex> {:error, {:already_started, ...}} = Game.start_link [], name: "player_1"
```

When a process has been registered, you can send messages via registry just by using the lock name
```
iex> GenServer.cast({:via, Relocker.Registry, "player_1"}, :stop) 
```


License notice
==============

Parts of the codebase like `lib/server.ex` and `lib/fsm.ex` heavily borrow from this
project: https://github.com/tsharju/elixir_locker.

