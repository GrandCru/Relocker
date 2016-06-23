defmodule Relocker.Locker.Agent do
  use GenServer

  @behaviour Relocker.Locker

  alias Relocker.Lock
  alias Relocker.Utils

  def child_spec, do: :none

  def start_link(_opts) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def lock(name, metadata, lease_time_secs, time) do
    Agent.get_and_update(__MODULE__, fn state ->
      case read(state, name, time) do
        :error ->
          lock = %Lock{name: name, secret: Utils.random_string(32), metadata: metadata, valid_until: time + lease_time_secs, lease_time: lease_time_secs}
          state = Map.put(state, name, lock)
          {{:ok, lock}, state}
        _any ->
          {:error, state}
      end

    end)
  end

  def read(name, time) do
    Agent.get(__MODULE__, fn state ->
      case read(state, name, time) do
        :error ->
          :error
        lock ->
          {:ok, lock}
      end
    end)
  end

  def extend(%Lock{} = lock, time) do
    Agent.get_and_update(__MODULE__, fn state ->
      case read(state, lock.name, time) do
        :error ->
          {:error, state}
        my_lock ->
          if time <= my_lock.valid_until and my_lock.secret == lock.secret do
            lock = %{lock | :valid_until => time + lock.lease_time}
            state = Map.put(state, lock.name, lock)
            {{:ok, lock}, state}
          else
            {:error, state}
          end
      end
    end)
  end

  def unlock(%Lock{} = lock, time) do
    Agent.get_and_update(__MODULE__, fn state ->
      if Map.has_key?(state, lock.name) do
        entry = Map.get(state, lock.name)
        if entry.secret == lock.secret and time <= lock.valid_until do
          state = Map.delete(state, lock.name)
          {:ok, state}
        else
          {:error, state}
        end
      else
        {:error, state}
      end
    end)
  end

  def reset do
    Agent.get_and_update(__MODULE__, fn _ -> {:ok, %{}} end)
  end

  defp read(state, name, time) do
    if Map.has_key? state, name do
      lock = Map.get state, name
      if time <= lock.valid_until do
        lock
      else
        :error
      end
    else
      :error
    end
  end

end