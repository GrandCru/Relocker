defmodule Relocker.Registry do

  alias Relocker.Locker
  alias Relocker.Utils

  require Logger

  @initial_lease_length 10
  @initial_lease_threshold 2

  @doc """
  Registers the given `pid` to a `name` globally.
  """
  @spec register_name(any, pid) :: :yes | :no
  def register_name(name, pid, opts \\ []) do
    lease_length = Keyword.get opts, :lease_length, @initial_lease_length
    lease_threshold = Keyword.get opts, :lease_threshold, @initial_lease_threshold
    case Locker.lock(name, %{pid: pid, node: node}, lease_length, Utils.time) do
      {:ok, lock} ->
        if pid == self do
          Process.put(:'$relock_lock', lock)
        end
        Process.send_after(pid, :'$relock_extend', (lease_length - lease_threshold) * 1000)
        Logger.debug "Registered #{inspect name} for #{inspect pid}"
        :yes
      :error ->
        Logger.warn "Unable to register #{inspect name} for pid #{inspect pid}"
        :no
    end
  end

  @doc """
  Finds the process identifier for the given `name`.
  """
  @spec whereis_name(any) :: pid | :undefined
  def whereis_name(name) do
    case Locker.read(name, Utils.time) do
      {:ok, lock} ->
        lock.metadata.pid
      :error ->
        :undefined
    end
  end

  @doc """
  Unregisters the given `name`.
  """
  @spec unregister_name(any) :: any
  def unregister_name(name) do
    case Locker.read(name) do
      {:ok, lock} ->
        Locker.unlock(lock, Utils.time)
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
    Logger.debug "unregister #{inspect lock}"
    Locker.unlock(lock, Utils.time)
  end

  @doc """
  Send message to the registered process.
  """
  def send(name, msg) do
    pid = whereis_name(name)
    if pid != :undefined do
      Kernel.send(pid, msg)
    else
      {:badarg, {name, msg}}
    end
  end

end