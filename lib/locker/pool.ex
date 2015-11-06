defmodule Relocker.Locker.Pool do

  alias Relocker.Lock

  @behaviour Relocker.Locker

  def child_spec do
    env = Application.get_env :relocker, :pool, []
    :poolboy.child_spec __MODULE__, Keyword.merge(default_config, env), []
  end

  def start_link(args) do
    GenServer.start_link Relocker.Locker.Redis, args
  end

  def lock(name, metadata, lease_time_secs, time) do
    :poolboy.transaction __MODULE__, fn pid -> 
      GenServer.call pid, {:lock, name, metadata, lease_time_secs, time}
    end
  end

  def read(name, time) do
    :poolboy.transaction __MODULE__, fn pid -> 
      GenServer.call pid, {:read, name, time}
    end
  end

  def extend(%Lock{} = lock, time) do
    :poolboy.transaction __MODULE__, fn pid -> 
      GenServer.call pid, {:extend, lock, time}
    end
  end

  def unlock(%Lock{} = lock, time) do
    :poolboy.transaction __MODULE__, fn pid -> 
      GenServer.call pid, {:unlock, lock, time}
    end
  end

  def reset do
    :poolboy.transaction __MODULE__, fn pid ->
      GenServer.call pid, :reset
    end
  end

  def stop do
    :poolboy.transaction __MODULE__, fn pid ->
      GenServer.call pid, :stop
    end
  end

  def default_config do
    [
      name: { :local, Relocker.Locker.Pool },
      worker_module: Relocker.Locker.Pool,
      size: 5,
      max_overflow: 10
    ]
  end

end