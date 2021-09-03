defmodule Redlock.NodeChooser do
  def choose(key) do
    [store_mod, store] = FastGlobal.get(:redlock_nodes)
    store_mod.choose(store, key)
  end

  def init(opts) do
    store_mod = Keyword.fetch!(opts, :store_mod)
    pools_list = Keyword.fetch!(opts, :pools_list)

    store = store_mod.new(pools_list)

    FastGlobal.put(:redlock_nodes, [store_mod, store])
  end
end
