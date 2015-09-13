defmodule RelockerServerTest do
  use ExUnit.Case, async: false

  alias Relocker.Registry

  alias Relocker.Test.NamedServer

  test "start" do

    Application.put_env(:relocker, :locker, Relocker.Locker.Agent)

    {:ok, pid} = NamedServer.start_link([], name: "my_little_server")

    assert pid == Registry.whereis_name "my_little_server"

    Registry.send("my_little_server", :hello)

    :timer.sleep 100

    assert :undefined == Registry.whereis_name "my_little_server"

  end

end
