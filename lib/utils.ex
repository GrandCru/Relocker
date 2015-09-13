defmodule Relocker.Utils do

  def random_string(len \\ 32), do: Base.encode64(:crypto.strong_rand_bytes(len))

  def time do
    {mega_secs, secs, _micro_secs} = :os.timestamp
    mega_secs * 1000000 + secs
  end

end