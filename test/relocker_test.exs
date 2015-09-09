defmodule RelockerTest do
  use ExUnit.Case
  use Timex

  alias Relocker.Registry
  alias Relocker.Utils
  alias Relocker.Test.Utils, as: TestUtils

  @lease_time_secs 5

  test "lock/unlock" do

    now = TestUtils.time(0)
    
    {:ok, lock} = Registry.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, now

    assert lock.name === :my_lock_name
    assert lock.valid_until == Utils.secs(now) + @lease_time_secs
    assert lock.metadata.some_metadata == 10

    {:ok, lock} = Registry.read :my_lock_name, now

    assert lock.name === :my_lock_name
    assert lock.valid_until == Utils.secs(now) + @lease_time_secs

    assert lock.metadata.some_metadata == 10

    assert :error == Registry.read :my_lock_name, TestUtils.time(1)

    {:ok, new_lock} = Registry.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, TestUtils.time(1)

    assert new_lock.secret != lock.secret

    assert :error == Registry.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, TestUtils.time(1)

    assert :error == Registry.unlock lock, TestUtils.time(1)
    assert :error == Registry.unlock lock, TestUtils.time(0)

    assert :ok == Registry.unlock new_lock, TestUtils.time(1)

    assert :error == Registry.unlock new_lock, TestUtils.time(1)

  end
end
