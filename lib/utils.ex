defmodule Relocker.Utils do

  use Timex

  def seed_random() do
    <<a::32, b::32, c::32>> = :crypto.rand_bytes(12)
    :random.seed(a, b, c)
  end

  def random_string(0) do
    []
  end
  def random_string(length) do
    [random_char() | random_string(length - 1)]
  end

  def random_char() do
    chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    :lists.nth(:random.uniform(:erlang.length(chars)), chars)
  end

  def secs(%Timex.DateTime{} = time), do: time |> Date.to_secs

end