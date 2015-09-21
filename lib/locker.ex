defmodule Relocker.Locker do

  use Behaviour

  require Logger

  alias Relocker.Utils
  alias Relocker.Lock

  @type lock_name :: binary | atom

  defcallback start_link(opts :: []) :: {:ok, pid}

  defcallback lock(name :: lock_name, metadata :: any, lease_time_secs :: integer, current_time :: integer) :: {:ok, Lock.t} | :error

  defcallback read(name :: lock_name, current_time :: integer) :: {:ok, Lock.t} | :error

  defcallback extend(lock :: Lock.t, current_time :: integer) :: {:ok, Lock.t} | :error

  defcallback unlock(lock :: Lock.t, current_time :: integer) :: :ok | :error

  defcallback reset() :: :ok | :error

  # Client

  def start_link(opts) do
    impl.start_link(opts)
  end

  def lock(name, metadata, lease_time_secs, current_time \\ Utils.time) when (is_binary(name) or is_atom(name)) and is_integer(lease_time_secs) do
    impl.lock name, metadata, lease_time_secs, current_time
  end

  def read(name, current_time \\ Utils.time) do
    impl.read name, current_time
  end

  def extend(%Lock{} = lock, current_time \\ Utils.time) do
    impl.extend lock, current_time
  end

  def unlock(%Lock{} = lock, current_time \\ Utils.time) do
    impl.unlock lock, current_time
  end

  def reset do
    impl.reset
  end

  def impl do
    case Application.get_env(:relocker, :locker) do
      nil ->
        raise """
        No locker implementation defined! Please define one by adding `:relocker, :locker, <LockerModule>` to Application config.
        """
      module ->
        module
    end
  end

end