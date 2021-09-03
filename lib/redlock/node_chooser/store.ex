defmodule Redlock.NodeChooser.Store do
  @callback new(pools_list :: [list]) :: any

  @callback choose(store :: any, resource :: String.t()) :: list
end
