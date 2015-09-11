defmodule RelockerServerTest do
  use ExUnit.Case

  alias Relocker.Registry
  alias Relocker.ProcessRegistry

  alias Relocker.Test.NamedServer
  
  @lease_time_secs 5

  setup_all do
    Application.put_env(:relocker, :registry, Relocker.Registry.Agent)
    :ok
  end

  setup do
    Registry.reset
    :ok
  end

  setup do
    Registry.reset
  end

  test "start" do

    {:ok, pid} = NamedServer.start_link([], name: "my_little_server")

    assert pid == ProcessRegistry.whereis_name "my_little_server"

    GenServer.cast(pid, :stop)

    :timer.sleep 100

    assert :undefined == ProcessRegistry.whereis_name "my_little_server"

  end

end
