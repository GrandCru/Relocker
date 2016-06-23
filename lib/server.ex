defmodule Relocker.Server do

  @moduledoc ~s"""

  See: https://github.com/tsharju/elixir_locker/blob/master/lib/elixir_locker/server.ex

  The MIT License (MIT)

  Copyright (c) 2015 Teemu Harju

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all
  copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
  """

  @doc false
  defmacro __using__(options) do
    lease_length    = Keyword.get(options, :lease_length, 5)
    lease_threshold = Keyword.get(options, :lease_threshold, 1)

    quote do
      @lease_length    unquote(lease_length)
      @lease_threshold unquote(lease_threshold)

      use GenServer

      def start(args, opts \\ []) do
        if Keyword.has_key?(opts, :name) do
          name = Keyword.get(opts, :name)
          opts = Keyword.put(opts, :name, {:via, Relocker.Registry, name})
          args = Keyword.put(args, :name, name)
          GenServer.start(__MODULE__, args, opts)
        else
          GenServer.start(__MODULE__, args, opts)
        end
      end

      def start_link(args, opts \\ []) do
        if Keyword.has_key?(opts, :name) do
          name = Keyword.get(opts, :name)
          opts = Keyword.put(opts, :name, {:via, Relocker.Registry, name})
          args = Keyword.put(args, :name, name)
          GenServer.start_link(__MODULE__, args, opts)
        else
          GenServer.start_link(__MODULE__, args, opts)
        end
      end

      # GenServer API

      def handle_info(:'$relock_extend', state) do
        lock = Process.get(:'$relock_lock')
        lock = put_in(lock.lease_time, @lease_length)
        case Relocker.Locker.extend(lock, Relocker.Utils.time) do
          {:ok, lock} ->
            Process.put(:'$relock_lock', lock)
            # schedule new lock lease extend
            Process.send_after self, :'$relock_extend', (@lease_length - @lease_threshold) * 1000
            {:noreply, state}
          error ->
            {:stop, error, state}
        end
      end

      def terminate(_reason, _state) do
        Relocker.Registry.unregister
        :ok
      end

      defoverridable [terminate: 2]

    end
  end

end