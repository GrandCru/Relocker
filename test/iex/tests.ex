defmodule IExTests do

  alias Relocker.Locker
  alias Relocker.Utils

  @lease_time_secs 5

  def lock_and_release(), do: lock_and_release(10000, 1000)
  def lock_and_release(num_locks, wait_time) do
    start = Utils.time
    for n <- 0..num_locks do
      name = "lock_#{n}"
      {:ok, _lock} = Locker.lock name, %{some_metadata: 10}, @lease_time_secs, Utils.time
      spawn fn ->
        :timer.sleep wait_time
        now = Utils.time
        {:ok, lock} = Locker.read name, now
        :ok == Locker.unlock lock, now
      end
    end
    elapsed_ms = Utils.time - start
    {:completed, :elapsed_ms, elapsed_ms, :locks, num_locks, :avg, elapsed_ms/num_locks}
  end

end