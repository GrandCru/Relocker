defmodule Relocker.Test.NamedServer do

  use Relocker.Server
  require Logger

  def init(opts) do
    super(opts)
    Logger.debug "NamedServer starts"
    {:ok, %{}}
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state}
  end

  def terminate(reason, state) do
    super(reason, state)
    Logger.debug "NamedServer terminate"
  end

end