defmodule RelockerTest do
  use ExUnit.Case

  alias Relocker.Locker
  alias Relocker.Test.Utils, as: TestUtils

  @lease_time_secs 5

  setup_all do
    Application.put_env(:relocker, :locker, Relocker.Locker.Agent)
    :ok
  end

  setup do
    Locker.reset
    :ok
  end

  test "lock/unlock" do

    now = TestUtils.time(0)

    {:ok, lock} = Locker.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, now

    assert lock.name === :my_lock_name
    assert lock.valid_until == now + @lease_time_secs
    assert lock.metadata.some_metadata == 10

    {:ok, lock} = Locker.read :my_lock_name, now

    assert lock.name === :my_lock_name
    assert lock.valid_until == now + @lease_time_secs

    assert lock.metadata.some_metadata == 10

    assert :error == Locker.read :my_lock_name, TestUtils.time(1)

    {:ok, new_lock} = Locker.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, TestUtils.time(1)

    assert new_lock.secret != lock.secret

    assert :error == Locker.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, TestUtils.time(1)

    assert :error == Locker.unlock lock, TestUtils.time(1)
    assert :error == Locker.unlock lock, TestUtils.time(0)

    assert :ok == Locker.unlock new_lock, TestUtils.time(1)

    assert :error == Locker.unlock new_lock, TestUtils.time(1)

  end

  test "extend lease" do

    now = TestUtils.time(3)

    {:ok, lock} = Locker.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, now

    now = now + 1

    {:ok, new_lock} = Locker.extend(lock, now)

    assert :error == Locker.extend(%{lock | :secret => "foo"}, now)

    assert lock.valid_until == new_lock.valid_until - 1

    now = now + 1 + @lease_time_secs

    assert :error == Locker.extend(lock, now)

    assert :error == Locker.extend(lock, TestUtils.time(4))

  end

end
