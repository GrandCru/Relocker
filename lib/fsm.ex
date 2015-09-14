defmodule Relocker.Fsm do

  @doc ~s"""
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

  defmacro __using__(options) do
    lease_length    = Keyword.get(options, :lease_length, 5)
    lease_threshold = Keyword.get(options, :lease_threshold, 2)

    quote location: :keep do
      @lease_length    unquote(lease_length)
      @lease_threshold unquote(lease_threshold)

      @behaviour :gen_fsm

      def start(args, opts \\ []) do
        name = Keyword.get(opts, :name)
        if name != nil do
          opts = Keyword.delete(opts, :name)
          :gen_fsm.start({:via, Relocker.Registry, name}, __MODULE__, args, opts)
        else
          :gen_fsm.start(__MODULE__, args, opts)
        end
      end
      
      def start_link(args, opts \\ []) do
        name = Keyword.get(opts, :name)
        if name != nil do
          opts = Keyword.delete(opts, :name)
          :gen_fsm.start_link({:via, Relocker.Registry, name}, __MODULE__, args, opts)
        else
          :gen_fsm.start_link(__MODULE__, args, opts)
        end
      end

      def handle_info({:'$relock_extend', lock}, statename, state) do
        case Relocker.extend(lock, Relocker.Utils.time) do
          {:ok, lock} ->
            Process.put(:'$relock_lock', lock)
            # schedule new lock lease extend
            Process.send_after(self, {:'$relock_extend', lock}, (@lease_length - @lease_threshold) * 1000)
            {:next_state, statename, state}
          error ->
            {:stop, error, state}
        end
      end
      
      def handle_event(_event, _statename, state) do
        {:stop, :not_implemented, state}
      end
      
      def handle_sync_event(_event, _from, statename, state) do
        {:stop, :not_implemented, {:error, :not_implemented}, state}
      end
      
      def code_change(_oldvsn, statename, state, _extra) do
        {:ok, statename, state}
      end
      
      def terminate(_reason, _statename, _state) do
        Relocker.Registry.unregister
        :ok
      end
      
      defoverridable [handle_event: 3, handle_sync_event: 4,
                      code_change: 4, terminate: 3]
      
    end
  end

end