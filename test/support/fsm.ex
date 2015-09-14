defmodule Relocker.Test.NamedFsm do

  use Relocker.Fsm

  def init(_) do
    {:ok, :started, %{}}
  end

  def handle_sync_event(:stop, from, :started, state) do
    :gen_fsm.reply(from, :ok)
    {:stop, :normal, state}
  end

  def terminate(reason, statename, state) do
    super(reason, statename, state)
    :ok
  end

end