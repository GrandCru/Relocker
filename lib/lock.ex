defmodule Relocker.Lock do

  @type t :: %Relocker.Lock{}
	
	defstruct name: "", metadata: nil, secret: "", valid_until: 0, lease_time: 0

end