defmodule Redlock.Supervisor do
  use Supervisor
  require Logger

  # default Connection options
  @default_pool_size 2
  @default_port 6379
  @default_ssl false
  @default_database nil
  @default_retry_interval_base 300
  @default_retry_interval_max 3_000
  @default_reconnection_interval_base 300
  @default_reconnection_interval_max 3_000

  # default Executor options
  @default_drift_factor 0.01
  @default_max_retry 5

  alias Redlock.NodeSupervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do
    prepare_global_config(opts)
    children(opts) |> Supervisor.init(strategy: :one_for_one)
  end

  defp children(opts) do
    pool_size = Keyword.get(opts, :pool_size, @default_pool_size)

    servers = Keyword.get(opts, :servers, [])
    cluster = Keyword.get(opts, :cluster, [])

    case choose_mode(servers, cluster) do
      :single ->
        setup_single_node(pool_size, servers)

      :cluster ->
        setup_cluster(pool_size, cluster)
    end
  end

  defp setup_single_node(pool_size, servers) do
    {pool_names, specs} = gather_node_setting(pool_size, servers)

    prepare_node_chooser(Redlock.NodeChooser.Store.SingleNode, [pool_names])

    specs
  end

  defp setup_cluster(pool_size, cluster) do
    node_settings =
      cluster
      |> Enum.map(&gather_node_setting(pool_size, &1))

    specs =
      node_settings
      |> Enum.map(fn {_, specs} -> specs end)
      |> List.flatten()

    pools_list =
      node_settings
      |> Enum.map(fn {pools, _} -> pools end)

    prepare_node_chooser(Redlock.NodeChooser.Store.HashRing, pools_list)

    specs
  end

  defp gather_node_setting(pool_size, servers) do
    servers
    |> Enum.map(&node_supervisor(&1, pool_size))
    |> Enum.unzip()
  end

  defp prepare_node_chooser(store_mod, pools_list) do
    Redlock.NodeChooser.init(store_mod: store_mod, pools_list: pools_list)
  end

  defp prepare_global_config(opts) do
    show_debug_logs = Keyword.get(opts, :show_debug_logs, false)
    drift_factor = Keyword.get(opts, :drift_factor, @default_drift_factor)
    max_retry = Keyword.get(opts, :max_retry, @default_max_retry)

    retry_interval_base =
      Keyword.get(
        opts,
        :retry_interval_base,
        @default_retry_interval_base
      )

    retry_interval_max =
      Keyword.get(
        opts,
        :retry_interval_max,
        @default_retry_interval_max
      )

    FastGlobal.put(:redlock_conf, %{
      drift_factor: drift_factor,
      max_retry: max_retry,
      retry_interval_base: retry_interval_base,
      retry_interval_max: retry_interval_max,
      show_debug_logs: show_debug_logs
    })
  end

  defp choose_mode(servers, cluster) when is_list(servers) and is_list(cluster) do
    cond do
      length(cluster) > 0 ->
        cluster |> Enum.each(&validate_server_setting(&1))
        :cluster

      length(servers) > 0 ->
        validate_server_setting(servers)
        :single

      true ->
        raise_error("should set proper format of :servers or :cluster")
    end
  end

  defp choose_mode(_servers, _cluster) do
    raise_error("should set proper format of :servers or :cluster")
  end

  defp validate_server_setting(servers) when is_list(servers) do
    if rem(length(servers), 2) != 0 do
      :ok
    else
      raise_error("should include odd number of host settings")
    end
  end

  defp validate_server_setting(_servers) do
    raise_error("invalid format of server list")
  end

  defp raise_error(msg) do
    raise "Redlock Configuration Exception: #{msg}"
  end

  defp node_supervisor(opts, pool_size) do
    host = Keyword.fetch!(opts, :host)
    port = Keyword.get(opts, :port, @default_port)
    ssl = Keyword.get(opts, :ssl, @default_ssl)
    auth = Keyword.get(opts, :auth, nil)
    database = Keyword.get(opts, :database, @default_database)

    interval_base =
      Keyword.get(
        opts,
        :reconnection_interval_base,
        @default_reconnection_interval_base
      )

    interval_max =
      Keyword.get(
        opts,
        :reconnection_interval_max,
        @default_reconnection_interval_max
      )

    name = Module.concat(Redlock.NodeSupervisor, "#{host}_#{port}")
    pool_name = Module.concat(Redlock.NodeConnectionPool, "#{host}_#{port}")

    {pool_name,
     supervisor(
       NodeSupervisor,
       [
         [
           name: name,
           host: host,
           port: port,
           ssl: ssl,
           database: database,
           auth: auth,
           pool_name: pool_name,
           reconnection_interval_base: interval_base,
           reconnection_interval_max: interval_max,
           pool_size: pool_size
         ]
       ],
       id: name
     )}
  end
end
