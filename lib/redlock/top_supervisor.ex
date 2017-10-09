defmodule Redlock.TopSupervisor do

  use Supervisor
  require Logger

  # default Connection options
  @default_pool_size 2
  @default_port 6379
  @default_retry_interval 300
  @default_reconnection_interval 5_000

  # default Executor options
  @default_drift_factor 0.01
  @default_max_retry 5

  alias Redlock.NodeSupervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    specs = children(opts)
    Logger.info "Redlock #{inspect specs}"
    supervise(specs, strategy: :one_for_one)
  end

  defp children(opts) do

    pool_size = Keyword.get(opts, :pool_size, @default_pool_size)

    servers = Keyword.fetch!(opts, :servers)
    validate_server_setting(servers)

    {pool_names, specs} = servers
                        |> Enum.map(&(node_supervisor(&1, pool_size)))
                        |> Enum.unzip()

    specs ++ [executor_worker(opts, pool_names)]

  end

  defp executor_worker(opts, servers) do
    drift_factor = Keyword.get(opts, :drift_factor, @default_drift_factor)
    max_retry = Keyword.get(opts, :max_retry, @default_max_retry)
    interval = Keyword.get(opts, :retry_interval, @default_retry_interval)

    worker(Redlock.Executor, [[servers:        servers,
                               drift_factor:   drift_factor,
                               max_retry:      max_retry,
                               retry_interval: interval]])
  end

  defp validate_server_setting(servers) when is_list(servers) do
    if rem(length(servers), 2) != 0 do
      :ok
    else
      raise ":servers options should include odd number of host settings"
    end
  end
  defp validate_server_setting(_servers) do
    raise ":servers option should be set and it also should be list"
  end

  defp node_supervisor(opts, pool_size) do

    host     = Keyword.fetch!(opts, :host)
    port     = Keyword.get(opts, :port, @default_port)
    interval = Keyword.get(opts, :reconnection_interval, @default_reconnection_interval)

    name      = Module.concat(Redlock.NodeSupervisor, "#{host}_#{port}")
    pool_name = Module.concat(Redlock.NodeConnectionPool, "#{host}_#{port}")

    {pool_name, supervisor(NodeSupervisor,
                      [[name:                  name,
                        host:                  host,
                        port:                  port,
                        pool_name:             pool_name,
                        reconnection_interval: interval,
                        pool_size:             pool_size]])}
  end

end
