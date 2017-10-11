defmodule Redlock.NodeChooser do

  use GenServer

  def choose(key) do
    GenServer.call(__MODULE__, {:choose, key})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do

    store_mod  = Keyword.fetch!(opts, :store_mod)
    pools_list = Keyword.fetch!(opts, :pools_list)

    store = store_mod.new(pools_list)

    {:ok, [store_mod, store]}

  end

  def handle_call({:choose, key}, _from, [store_mod, store]) do
    pools = store_mod.choose(store, key)
    {:reply, pools, [store_mod, store]}
  end

end
