defmodule Relocker.Test.Utils do

  use Timex

  def time(hour, min \\ "00") do
    DateFormat.parse! "2015-06-14T0#{hour}:#{min}:00Z", "{ISOz}"
  end

end