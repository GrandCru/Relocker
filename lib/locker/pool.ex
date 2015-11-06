defmodule Relocker.Locker.Pool do

  alias Relocker.Lock
  alias Relocker.Utils

  @behaviour Relocker.Locker

  def child_spec do
    :poolboy.child_spec __MODULE__, Application.fetch_env!(:relocker, :pool), []
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

end