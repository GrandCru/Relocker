defmodule Relocker.Lock do

  @type t :: %Relocker.Lock{}
	
	defstruct name: "", secret: "", valid_until: 0, metadata: nil

end