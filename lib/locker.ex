defmodule Relocker.Locker do
  @moduledoc """
  A module for acquiring a lock, extending it and releasing the lock.
  """

  use Behaviour

  require Logger

  alias Relocker.Utils
  alias Relocker.Lock

  @type lock_name :: binary | atom

  defcallback child_spec() :: Supervisor.Spec.spec | :none

  defcallback lock(name :: lock_name, metadata :: any, lease_time_secs :: integer, current_time :: integer) :: {:ok, Lock.t} | :error

  defcallback read(name :: lock_name, current_time :: integer) :: {:ok, Lock.t} | :error

  defcallback extend(lock :: Lock.t, current_time :: integer) :: {:ok, Lock.t} | :error

  defcallback unlock(lock :: Lock.t, current_time :: integer) :: :ok | :error

  defcallback reset() :: :ok | :error

  # Client

  def child_spec() do
    case impl.child_spec do
      :none ->
        import Supervisor.Spec, warn: false
        worker(Relocker.Locker, [[name: Relocker.Locker]])
      spec ->
        spec
    end
  end

  def start_link(opts \\ []) do
    impl.start_link opts
  end

  @doc "Try to acquire a lock. Returns `{:ok, %Lock{}}` if successful, if not `:error` is returned"
  def lock(name, metadata, lease_time_secs, current_time \\ Utils.time) when (is_binary(name) or is_atom(name)) and is_integer(lease_time_secs) do
    impl.lock name, metadata, lease_time_secs, current_time
  end

  @doc "Read lock with name `lock_name`. Returns `{:ok, %Lock{}}` if successful."
  def read(name, current_time \\ Utils.time) do
    impl.read name, current_time
  end

  @doc "Extend a lock. When successful a new lock struct is returned and that should be used for subsequent calls to this API."
  def extend(%Lock{} = lock, current_time \\ Utils.time) do
    impl.extend lock, current_time
  end

  @doc "Release a lock."
  def unlock(%Lock{} = lock, current_time \\ Utils.time) do
    impl.unlock lock, current_time
  end

  @doc "Reset, meant to be used for testing only."
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