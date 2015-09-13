defmodule Relocker.Registry do

  alias Relocker.Locker
  alias Relocker.Utils

  require Logger

  @doc """
  Registers the given `pid` to a `name` globally.
  """
  @spec register_name(any, pid) :: :yes | :no
  def register_name(name, pid) do
    case Locker.lock(name, %{pid: pid, node: node}, 5, Utils.time) do
      {:ok, lock} ->
        if pid == self do
          Process.put(:'$relock_lock', lock)
        end
        Process.send_after(pid, {:'$relock_extend', lock}, 1000)
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

  def send(name, msg) do
    pid = whereis_name(name)
    if pid != :undefined do
      Kernel.send(pid, msg)
    else
      {:badarg, {name, msg}}
    end
  end

end