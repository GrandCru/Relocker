defmodule RelockerServerTest do
  use ExUnit.Case

  alias Relocker.Locker
  alias Relocker.Registry

  alias Relocker.Test.NamedServer

  @lease_time_secs 5

  setup_all do
    Application.put_env(:relocker, :registry, Relocker.Locker.Agent)
    :ok
  end

  setup do
    Locker.reset
    :ok
  end

  setup do
    Locker.reset
  end

  test "start" do

    {:ok, pid} = NamedServer.start_link([], name: "my_little_server")

    assert pid == Registry.whereis_name "my_little_server"

    Registry.send("my_little_server", :hello)

    :timer.sleep 100

    assert :undefined == Registry.whereis_name "my_little_server"

  end

end
