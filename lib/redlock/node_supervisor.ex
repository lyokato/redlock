defmodule Redlock.NodeSupervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    Supervisor.start_link(__MODULE__, opts, name: name)
  end

  def init(opts) do
    name = Keyword.fetch!(opts, :pool_name)
    host = Keyword.fetch!(opts, :host)
    port = Keyword.fetch!(opts, :port)
    ssl = Keyword.fetch!(opts, :ssl)
    database = Keyword.fetch!(opts, :database)
    auth = Keyword.fetch!(opts, :auth)
    interval_base = Keyword.fetch!(opts, :reconnection_interval_base)
    interval_max = Keyword.fetch!(opts, :reconnection_interval_max)
    size = Keyword.fetch!(opts, :pool_size)

    children(name, host, port, ssl, database, auth, interval_base, interval_max, size)
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp children(name, host, port, ssl, database, auth, interval_base, interval_max, size) do
    [
      :poolboy.child_spec(
        name,
        pool_opts(name, size),
        host: host,
        port: port,
        ssl: ssl,
        database: database,
        auth: auth,
        reconnection_interval_base: interval_base,
        reconnection_interval_max: interval_max
      )
    ]
  end

  defp pool_opts(name, size) do
    [
      {:name, {:local, name}},
      {:worker_module, Redlock.ConnectionKeeper},
      {:size, size},
      {:max_overflow, 0}
    ]
  end
end
