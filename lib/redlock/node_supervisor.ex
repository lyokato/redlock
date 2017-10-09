defmodule Redlock.NodeSupervisor do

  use Supervisor
  require Logger

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do

    name     = Keyword.fetch!(opts, :pool_name)
    host     = Keyword.fetch!(opts, :host)
    port     = Keyword.fetch!(opts, :port)
    interval = Keyword.fetch!(opts, :reconnection_interval)
    size     = Keyword.fetch!(opts, :pool_size)

    children(name, host, port, interval, size)
    |> supervise(strategy: :one_for_one)

  end

  defp children(name, host, port, interval, size) do
    [:poolboy.child_spec(name,
                         pool_opts(name, size),
                         [host:                  host,
                          port:                  port,
                          reconnection_interval: interval])]
  end

  defp pool_opts(name, size) do
    [{:name, {:local, name}},
     {:worker_module, Redlock.ConnectionKeeper},
     {:size, size},
     {:max_overflow, size}]
  end

end
