defmodule Redlock.NodeChooser.Store.HashRing do
  alias ExHashRing.HashRing

  @behaviour Redlock.NodeChooser.Store
  require Logger

  @impl true
  def new(pools_list) do
    len = length(pools_list)

    ring =
      idx_list(len)
      |> Enum.reduce(HashRing.new(), fn idx, ring ->
        {:ok, ring2} = HashRing.add_node(ring, "#{idx}")
        ring2
      end)

    [ring, pools_list]
  end

  defp idx_list(0) do
    raise "must not come here"
  end

  defp idx_list(1) do
    # XXX Shouldn't be come here on production environment
    [0]
  end

  defp idx_list(len) do
    0..(len - 1) |> Enum.to_list()
  end

  @impl true
  def choose([ring, pools_list], key) do
    idx = HashRing.find_node(ring, key)
    Enum.at(pools_list, String.to_integer(idx))
  end
end
