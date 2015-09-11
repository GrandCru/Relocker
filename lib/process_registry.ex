defmodule Relocker.ProcessRegistry do

  use Behaviour

  alias Relocker.Registry

  @lock_lease_length 5
  @lock_lease_treshold 2

  @doc """
  Sends a message to the given `name`.
  """
  defcallback send(name :: any, msg :: any) :: :ok | {:badarg, {any, any}}

  @doc """
  Registers the given `pid` to a `name` globally.
  """
  @spec register_name(any, pid) :: :yes | :no
  def register_name(name, pid) do
    case Registry.lock(name, %{pid: pid, node: node}, @lease_time_secs, Utils.time) do
      {:ok, lock} ->
        if pid == self do
          Process.put(:'$relock_lock', lock)
        end
        Process.send(pid, {:'$relock_extend', lock, Utils.time}, @lock_lease_length - @lock_lease_treshold)
        :yes
      :error ->
        :no
    end
  end

  @doc """
  Finds the process identifier for the given `name`.
  """
  @spec whereis_name(any) :: pid | :undefined
  def whereis_name(name) do
    case Registry.read(name, Utils.time) do
      {:ok, lock} ->
        lock.pid
      :error ->
        :undefined
    end
  end
  
  @doc """
  Unregisters the given `name`.
  """
  @spec unregister_name(any) :: any
  def unregister_name(name) do
    case Registry.read(name) do
      {:ok, lock} ->
        Registry.unlock(lock, Utils.time)
      :error ->
        :undefined
    end
  end
  
  @doc """
  Unregisters the calling process.
  """
  @spec unregister :: any
  def unregister do
    lock = Process.get(:'$relock_lock')
    Registry.unlock(lock, Utils.time) 
  end

  def send(name, msg) do
    impl.send(name, msg)
  end

  def impl do
    case Application.get_env(:relocker, :process_registry) do
      nil ->
        raise "No process registry backend defined! Please check config.exs of this library to learn how to do it."
      module ->
        module
    end
  end

end