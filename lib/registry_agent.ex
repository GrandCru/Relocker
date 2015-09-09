defmodule Relocker.Registry.Agent do
  use GenServer

  @behaviour Relocker.Registry

  alias Relocker.Lock
  alias Relocker.Utils

  def start_link(opts) do
    Agent.start_link(fn ->
      Utils.seed_random
      HashDict.new
    end, name: __MODULE__)
  end

  def lock(name, lease_time_secs, metadata, time) do
    Agent.get_and_update(__MODULE__, fn state ->

      case read(state, name, time) do
        :error -> 
          lock = %Lock{name: name, secret: Utils.random_string(32), metadata: metadata, valid_until: secs(time) + lease_time_secs}
          state = HashDict.put(name, lock)
          {{:ok, lock}, state}
        _any ->
          {:error, state}
      end

    end)
  end

  def read(name, time) do
    Agent.get(__MODULE__, fn state -> read(state, name, time) end)
  end

  def extend(%Lock{} = lock, time) do
    Agent.get_and_update(__MODULE__, fn state ->
      result = if HashDict.has_key? lock.name do
        if secs(time) <= lock.valid_until do
          :ok
        else
          :error
        end
      else
        :error
      end
      {result, state}
    end)
  end

  def unlock(%Lock{} = lock, time) do
    Agent.get_and_update(__MODULE__, fn state ->
      result = if HashDict.has_key? lock.name do
        entry = HashDict.get state, lock.name
        if entry.secret == lock.secret and secs(time) <= lock.valid_until do
          :ok
        else
          :error
        end
      else
        :error
      end
      {result, state}
    end)
  end

  defp read(state, name, time) do
    if HashDict.has_key? name do
      lock = HashDict.get name
      if lock.valid_until <= secs(time) do
        lock
      else
        :error
      end
    else
      :error
    end
  end

  defp secs(time), do: time |> Date.to_secs

end