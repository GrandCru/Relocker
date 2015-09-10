defmodule Relocker.Registry.Redis do
  use GenServer
  use Timex

  import Exredis

  @behaviour Relocker.Registry

  alias Relocker.Lock
  alias Relocker.Utils

  # Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)_)
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

  # GenServer

  def init(_opts) do
    connection_string = Application.get_env(:relocker, :redis)
    redis = Exredis.start_using_connection_string connection_string
    {:ok, %{:redis => redis}}
  end

  def handle_call({:lock, name, metadata, lease_time_secs, time}, _from, state) do

    lock = %Lock{name: name, secret: Utils.random_string(32), metadata: metadata, valid_until: secs(time) + lease_time_secs, lease_time: lease_time_secs}
    
    case query(state.redis, ["SET", redis_key(name), lock.secret, "NX", "EX", lease_time_secs]) do

    end

  end

  def read_lock()


  defp redis_key(name) when is_atom(name), do: name |> Atom.to_string |> redis_key
  defp redis_key(name) when is_string(name), do: "relock:#{name}"


end