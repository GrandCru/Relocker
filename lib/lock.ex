defmodule Relocker.Lock do

  @type t :: %Relocker.Lock{}

  defstruct name: "", metadata: nil, secret: "", valid_until: 0, lease_time: 0

end

defimpl Inspect, for: Relocker.Lock do
  import Inspect.Algebra
  def inspect(lock, _opts) do
    concat ["%Relocker.Lock<name: #{inspect lock.name}, secret: #{inspect lock.secret} ...>"]
  end
end