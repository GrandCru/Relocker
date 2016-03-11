defmodule Relocker.Locker.Redis do
  @moduledoc """
  Aims to implement the algorithm for single redis server instance described at
  http://redis.io/topics/distlock
  """
  use GenServer

  import Exredis
  import Exredis.Script

  @behaviour Relocker.Locker

  alias Relocker.Lock
  alias Relocker.Utils

  # Client

  def child_spec, do: :none

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start_link_anonymous(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  def lock(name, metadata, lease_time_secs, time) do
    GenServer.call(__MODULE__, {:lock, name, metadata, lease_time_secs, time})
  end

  def read(name, time) do
    GenServer.call(__MODULE__, {:read, name, time})
  end

  def extend(%Lock{} = lock, time) do
    GenServer.call(__MODULE__, {:extend, lock, time})
  end

  def unlock(%Lock{} = lock, time) do
    GenServer.call(__MODULE__, {:unlock, lock, time})
  end

  def reset do
    GenServer.call(__MODULE__, :reset)
  end

  def stop do
    GenServer.call(__MODULE__, :stop)
  end

  # GenServer

  def init(opts) do
    connection_string = Application.get_env(:relocker, :redis) || Keyword.get(opts, :redis, nil)
    if connection_string == nil do
      raise "No redis connection string defined! Please add `:relocker, :redis, \"redis:://<address>:<port>\"` to the application configuration."
    end
    redis = Exredis.start_using_connection_string connection_string
    {:ok, %{:redis => redis}}
  end

  def handle_call({:lock, name, metadata, lease_time_secs, time}, _from, state) do

    lock = %Lock{name: name, secret: Utils.random_string(32), metadata: metadata, valid_until: time + lease_time_secs, lease_time: lease_time_secs}

    case query(state.redis, ["SET", redis_key(name), lock.secret, "NX", "EX", lease_time_secs]) do
      "OK" ->
        state.redis |> query(["SET", redis_key_meta(name), :erlang.term_to_binary(lock), "EX", lease_time_secs])
        {:reply, {:ok, lock}, state}
      _ ->
        {:reply, :error, state}
    end

  end

  def handle_call({:read, name, time}, _from, state) do
    case query(state.redis, ["GET", redis_key(name)]) do
      :undefined ->
        {:reply, :error, state}
      nil ->
        {:reply, :error, state}
      secret ->
        lock = state.redis |> query(["GET", redis_key_meta(name)]) |> decode
        if lock.secret == secret and time <= lock.valid_until do
          {:reply, {:ok, lock}, state}
        else
          {:reply, :error, state}
        end
    end
  end

  def handle_call({:extend, lock, time}, _from, state) do
    res = extend_lock(state.redis, [redis_key(lock.name)], [lock.secret, lock.lease_time])
    case res do
      "OK" ->
        lock = put_in(lock.valid_until, time + lock.lease_time)
        state.redis |> query(["SET", redis_key_meta(lock.name), :erlang.term_to_binary(lock), "EX", lock.lease_time])
        {:reply, {:ok, lock}, state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call({:unlock, lock, _time}, _from, state) do
    res = delete_lock(state.redis, [redis_key(lock.name)], [lock.secret])
    case res do
      "1" ->
        {:reply, :ok, state}
      _ ->
        {:reply, :error, state}
    end
  end

  def handle_call(:reset, _from, state) do
    keys = state.redis |> query(["KEYS", "relock:*"])
    state.redis |> query(["DEL"] ++ keys)
    {:reply, :ok, state}
  end

  def handle_call(:stop, _from, state) do
    Exredis.stop state.redis
    {:stop, :normal, state}
  end

  defredis_script :extend_lock, """
    if redis.call("get",KEYS[1]) == ARGV[1] then
        return redis.call("set", KEYS[1], ARGV[1], "EX", ARGV[2])
    else
        return 0
    end
  """

  defredis_script :delete_lock, """
    if redis.call("get",KEYS[1]) == ARGV[1] then
        return redis.call("del", KEYS[1])
    else
        return 0
    end
  """

  defp redis_key(name) when is_atom(name), do: name |> Atom.to_string |> redis_key
  defp redis_key(name) when is_binary(name), do: "relock:#{scope}:l:#{name}"

  defp redis_key_meta(name) when is_atom(name), do: name |> Atom.to_string |> redis_key_meta
  defp redis_key_meta(name) when is_binary(name), do: "relock:#{scope}:m:#{name}"

  defp decode(:undefined), do: :undefined
  defp decode(bin) do
    lock = :erlang.binary_to_term(bin)
    put_in(lock.secret, to_string(lock.secret))
  end

  defp scope do
    Application.get_env(:relock, :key_scope, "scope")
  end

end