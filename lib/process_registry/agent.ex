defmodule Relocker.ProcessRegistry.Agent do

	@behaviour Relocker.ProcessRegistry

  def send(name, msg) do
    pid = Relocker.ProcessRegistry.whereis_name(name)
    if pid != :undefined do
      Kernel.send(pid, msg)
    else
      {:badarg, {name, msg}}
    end
  end	

end