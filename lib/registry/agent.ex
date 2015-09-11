defmodule Relocker.Registry.Agent do
  use GenServer

  @behaviour Relocker.Registry

  alias Relocker.Lock
  alias Relocker.Utils

  def start_link(_opts \\ []) do
    Agent.start_link(fn ->
      Utils.seed_random
      HashDict.new
    end, name: __MODULE__)
  end

  def lock(name, metadata, lease_time_secs, time) do
    Agent.get_and_update(__MODULE__, fn state ->

      case read(state, name, time) do
        :error ->
          lock = %Lock{name: name, secret: Utils.random_string(32), metadata: metadata, valid_until: time + lease_time_secs, lease_time: lease_time_secs}
          state = HashDict.put(state, name, lock)
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
      result =
        case read(state, lock.name, time) do
          :error ->
            :error
          my_lock ->
            if time <= my_lock.valid_until and my_lock.secret == lock.secret do
              lock = %{lock | :valid_until => time + lock.lease_time}
              state = HashDict.put(state, lock.name, lock)
              {:ok, lock}
            else
              :error
            end
        end
      {result, state}
    end)
  end

  def unlock(%Lock{} = lock, time) do
    Agent.get_and_update(__MODULE__, fn state ->
      result = if HashDict.has_key? state, lock.name do
        entry = HashDict.get state, lock.name
        if entry.secret == lock.secret and time <= lock.valid_until do
          state = HashDict.delete state, lock.name
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

  def reset do
    Agent.get_and_update(__MODULE__, fn _ ->
      {:ok, HashDict.new}
    end)
  end

  defp read(state, name, time) do
    if HashDict.has_key? state, name do
      lock = HashDict.get state, name
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