defmodule Relocker.Utils do

  def seed_random() do
    <<a::32, b::32, c::32>> = :crypto.rand_bytes(12)
    :random.seed(a, b, c)
  end

  defp random_string(0) do
    []
  end
  defp random_string(length) do
    [random_char() | random_string(length - 1)]
  end

  defp random_char() do
    chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
    :lists.nth(:random.uniform(:erlang.length(chars)), chars)
  end

end