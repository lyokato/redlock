defmodule Redlock.NodeChooser.Store.SingleNode do
  @behaviour Redlock.NodeChooser.Store

  @impl true
  def new([pools]) do
    pools
  end

  @impl true
  def choose(store, _key) do
    store
  end
end
