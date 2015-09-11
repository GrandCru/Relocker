defmodule Relocker.Server do

  @doc false
  defmacro __using__(options) do
    lease_length    = Keyword.get(options, :lease_length, 5)
    lease_threshold = Keyword.get(options, :lease_threshold, 1)
    
    quote do
      @lease_length    unquote(lease_length)
      @lease_threshold unquote(lease_threshold)

      use GenServer

      def start(args, opts \\ []) do
        name = Keyword.get(opts, :name)
        if name != nil do
          opts = Keyword.put(opts, :name, {:via, Relocker.ProcessRegistry, name})
          args = Keyword.put(args, :name, name)
        end
        GenServer.start(__MODULE__, args, opts)
      end
        
      def start_link(args, opts \\ []) do
        name = Keyword.get(opts, :name)
        if name != nil do
          opts = Keyword.put(opts, :name, {:via, Relocker.ProcessRegistry, name})
          args = Keyword.put(args, :name, name)
        end
        GenServer.start_link(__MODULE__, args, opts)
      end
      
      # GenServer API
      
      def handle_info({:'$relock_extend', lock}, state) do
        case Relocker.Registry.extend(lock, Relocker.Utils.time) do
          {:ok, lock} ->
            Process.put(:'$relock_lock', lock)
            # schedule new lock lease extend
            Process.send_after(self, {:'$relock_extend', lock}, (@lease_length - @lease_threshold) * 1000)
            {:noreply, state}
          error ->
            {:stop, error, state}
        end
      end

      def init(_) do
        Process.flag(:trap_exit, true)
      end
      
      defoverridable [init: 1]

      def terminate(_reason, _state) do
        Relocker.ProcessRegistry.unregister
        :ok
      end
      
      defoverridable [terminate: 2]
      
    end
  end

end