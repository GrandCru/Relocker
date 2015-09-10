defmodule RelockerRedis do
  use ExUnit.Case
  use Timex

  alias Relocker.Registry
  alias Relocker.Utils
  alias Relocker.Test.Utils, as: TestUtils

  @moduletag :redis

  @lease_time_secs 5

  setup_all do
    Application.put_env(:relocker, :registry, Relocker.Registry.Redis)
    {:ok, _pid} = Relocker.Registry.Redis.start_link
    :ok
  end

  setup do
    Registry.reset
  end

  test "lock/unlock" do

    now = TestUtils.time(0)
    
    {:ok, lock} = Registry.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, now
    :error = Registry.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, now

    assert lock.name === :my_lock_name
    assert lock.valid_until == Utils.secs(now) + @lease_time_secs
    assert lock.metadata.some_metadata == 10

    {:ok, lock} = Registry.read :my_lock_name, now

    assert lock.name === :my_lock_name
    assert lock.valid_until == Utils.secs(now) + @lease_time_secs

    assert lock.metadata.some_metadata == 10

    assert :error == Registry.read :my_lock_name, TestUtils.time(1)

    assert :error == Registry.unlock(put_in(lock.secret, "lollers"))

    assert :ok == Registry.unlock(lock)
    assert :error == Registry.unlock(lock)

    assert :error == Registry.read :my_lock_name, TestUtils.time(0)

    {:ok, new_lock} = Registry.lock :my_lock_name_2, %{some_metadata: 10}, @lease_time_secs, TestUtils.time(1)

    assert new_lock.secret != lock.secret

    assert :ok == Registry.unlock(new_lock)

  end

  test "extend lease" do

    now = TestUtils.time(3)
    
    {:ok, lock} = Registry.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, now

    now = Timex.Date.add(now, Time.to_timestamp(1, :secs))

    assert :error == Registry.extend(%{lock | :secret => "foo"}, now)

    {:ok, new_lock} = Registry.extend(lock, now)

    assert lock.valid_until < new_lock.valid_until

  end

end
