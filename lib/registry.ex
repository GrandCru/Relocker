defmodule Relocker.Registry do

  use Behaviour
  use Timex

  alias Relocker.Lock

  @type lock_name :: binary | atom

  defcallback start_link(opts :: []) :: {:ok, pid}
  
  defcallback lock(name :: lock_name, metadata :: any, lease_time_secs :: integer, time :: Date.t) :: {:ok, Lock.t} | :error

  defcallback read(name :: lock_name, time :: Date.t) :: {:ok, Lock.t} | :error
  
  defcallback extend(lock :: Lock.t, time :: Date.t) :: {:ok, Lock.t} | :error
  
  defcallback unlock(lock :: Lock.t, time :: Date.t) :: :ok | :error

  defcallback reset() :: :ok | :error

  # Client

  def start_link(opts) do
    impl.start_link(opts)
  end

  def lock(name, metadata, lease_time_secs, time \\ Date.now) when (is_binary(name) or is_atom(name)) and is_integer(lease_time_secs) do
    impl.lock name, metadata, lease_time_secs, time
  end

  def read(name, time \\ Date.now) do
    impl.read name, time
  end

  def extend(%Lock{} = lock, time \\ Date.now) do
    impl.extend lock, time
  end

  def unlock(%Lock{} = lock, time \\ Date.now) do
    impl.unlock lock, time
  end

  def reset do
    impl.reset
  end

  def impl do
    case Application.get_env(:relocker, :registry) do
      nil ->
        raise "No registry backend defined! Please check config.exs of this library to learn how to do it."
      module ->
        module
    end
  end

end