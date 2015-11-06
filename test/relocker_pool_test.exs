defmodule RelockerPoolTest do
  use ExUnit.Case, async: false

  alias Relocker.Locker.Pool, as: Locker
  alias Relocker.Test.Utils, as: TestUtils

  alias Relocker.Registry

  alias Relocker.Test.NamedServer
  alias Relocker.Test.NamedFsm

  @lease_time_secs 5
  @moduletag :redis

  setup_all do

    Application.get_env :relocker, :locker, Relocker.Locker.Pool
    Application.put_env :relocker, :redis, "redis://192.168.33.11:6379"

    children = [
      Locker.child_spec
    ]

    opts = [strategy: :one_for_one, name: RelockerPoolTest.Supervisor]
    {:ok, _pid} = Supervisor.start_link(children, opts)

    :ok
  end

  setup do
    Locker.reset
    :ok
  end

  test "lock" do

    now = TestUtils.time(0)

    {:ok, lock} = Locker.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, now
    assert :error = Locker.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, now

    assert lock.name === :my_lock_name
    assert lock.valid_until == now + @lease_time_secs
    assert lock.metadata.some_metadata == 10

    {:ok, lock} = Locker.read :my_lock_name, now

    assert lock.name === :my_lock_name
    assert lock.valid_until == now + @lease_time_secs

    assert lock.metadata.some_metadata == 10

    assert :error == Locker.read :my_lock_name, TestUtils.time(1)

    assert :error == Locker.unlock(put_in(lock.secret, "lollers"), TestUtils.time(1))

    assert :ok == Locker.unlock(lock, TestUtils.time(1))
    assert :error == Locker.unlock(lock, TestUtils.time(1))

    assert :error == Locker.read :my_lock_name, TestUtils.time(0)

    {:ok, new_lock} = Locker.lock :my_lock_name_2, %{some_metadata: 10}, @lease_time_secs, TestUtils.time(1)

    assert new_lock.secret != lock.secret

    assert :ok == Locker.unlock(new_lock, TestUtils.time(1))

  end


  test "extend lease" do

    now = TestUtils.time(3)

    {:ok, lock} = Locker.lock :my_lock_name, %{some_metadata: 10}, @lease_time_secs, now

    now = now + 1

    assert :error == Locker.extend(%{lock | :secret => "foo"}, now)

    {:ok, new_lock} = Locker.extend(lock, now)

    assert lock.valid_until < new_lock.valid_until

  end

   test :genserver do

    {:ok, pid} = NamedServer.start_link([], name: "my_little_server")

    assert pid == Registry.whereis_name "my_little_server"

    assert {:error, {:already_started, pid}} == NamedServer.start_link([], name: "my_little_server")

    send pid, :'$relock_extend'

    assert GenServer.cast({:via, Registry, "my_little_server"}, :stop) == :ok

    :timer.sleep 100

    assert :undefined == Registry.whereis_name "my_little_server"

  end

  test :fsm do

    {:ok, pid} = NamedFsm.start_link([], name: "my_little_fsm")

    assert pid == Registry.whereis_name "my_little_fsm"

    send pid, :'$relock_extend'

    assert :gen_fsm.sync_send_all_state_event({:via, Registry, "my_little_fsm"}, :stop) == :ok

  end

end