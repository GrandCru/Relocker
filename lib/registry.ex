defmodule Relocker.Registry do

  use Behaviour
  use Timex

  alias Relocker.Lock

  defcallback start_link(opts :: []) :: {:ok, pid}
  
  defcallback lock(name :: binary, lease_time_secs :: integer, metadata :: any, time :: Date.t) :: {:ok, Lock.t} | :error

  defcallback read(name :: binary, time :: Date.t) :: {:ok, Lock.t} | :error
  
  defcallback extend(lock :: Lock.t, time :: Date.t) :: :ok | :error
  
  defcallback unlock(lock :: Lock.t, time :: Date.t) :: :ok | :error

  # Client

  def start_link(opts) do
    impl.start_link(opts)
  end

  def lock(name, lease_time_secs, metadata, time \\ Date.now) do
    impl.lock name, lease_time_secs, metadata, time
  end

  def extend(%Lock{} = lock, time \\ Date.now) do
    impl.extend lock, time
  end

  def unlock(%Lock{} = lock, time \\ Date.now) do
    impl.unlock lock, time
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