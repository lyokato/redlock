defmodule Redlock.NodeChooser do

  use GenServer

  def choose(key) do
    GenServer.call(__MODULE__, {:choose, key})
  end

  def start_link(cluster) do
    GenServer.start_link(__MODULE__, cluster, name: __MODULE__)
  end

  def init(cluster) do
    ring = cluster |> Enum.reduce(HashRing.new(), &(HashRing.add_node(&2, &1)))
    {:ok, ring}
  end

  def handle_call({:choose, key}, _from, ring) do
    servers = HashRing.key_to_node(ring, key)
    {:reply, servers, ring}
  end

end
