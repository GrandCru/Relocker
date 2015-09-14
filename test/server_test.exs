defmodule RelockerServerTest do
  use ExUnit.Case, async: false

  alias Relocker.Registry

  alias Relocker.Test.NamedServer
  alias Relocker.Test.NamedFsm

  test :genserver do

    Application.put_env(:relocker, :locker, Relocker.Locker.Agent)

    {:ok, pid} = NamedServer.start_link([], name: "my_little_server")

    assert pid == Registry.whereis_name "my_little_server"

    assert GenServer.cast({:via, Registry, "my_little_server"}, :stop) == :ok

    :timer.sleep 100

    assert :undefined == Registry.whereis_name "my_little_server"

  end

  test :fsm do

    Application.put_env(:relocker, :locker, Relocker.Locker.Agent)

    {:ok, pid} = NamedFsm.start_link([], name: "my_little_fsm")

    assert pid == Registry.whereis_name "my_little_fsm"

    assert :gen_fsm.sync_send_all_state_event({:via, Registry, "my_little_fsm"}, :stop) == :ok

  end

end
