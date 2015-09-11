defmodule Relocker.ProcessRegistry.Redis do

	@behaviour Relocker.ProcessRegistry

  use GenServer
  import Exredis

  def send(_name, _msg) do
    raise "Not implemented yet!"
  end	


end