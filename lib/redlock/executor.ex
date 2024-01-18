defmodule Redlock.Executor do
  import Redlock.Util, only: [now: 0, random_value: 0, log: 3]

  alias Redlock.Command
  alias Redlock.ConnectionKeeper
  alias Redlock.NodeChooser

  # TTL = seconds
  def lock(resource, ttl) do
    do_lock(resource, ttl, random_value(), 0, FastGlobal.get(:redlock_conf))
  end

  def unlock(resource, value) do
    config = FastGlobal.get(:redlock_conf)

    NodeChooser.choose(resource)
    |> Enum.each(fn node ->
      case unlock_on_node(node, resource, value, config) do
        {:ok, _} ->
          log(
            config.log_level,
            "debug",
            "<Redlock> unlocked '#{resource}' successfully on node: #{node}"
          )

          :ok

        {:error, reason} ->
          log(
            config.log_level,
            "error",
            "<Redlock> failed to execute redis-unlock-command: #{inspect(reason)}"
          )

          :error
      end
    end)
  end

  def extend(resource, value, ttl) do
    do_extend(resource, value, ttl, FastGlobal.get(:redlock_conf))
  end

  defp do_lock(resource, ttl, value, attempts, %{max_retry: max_retry} = config) do
    {number_of_success, quorum, validity} =
      lock_helper("lock", &lock_on_node/5, resource, value, ttl, config)

    if number_of_success >= quorum and validity > 0 do
      log(config.log_level, "debug", "<Redlock> created lock for '#{resource}' successfully")

      {:ok, value}
    else
      if attempts < max_retry do
        log(
          config.log_level,
          "info",
          "<Redlock> failed to lock '#{resource}', retry after interval"
        )

        calc_backoff(config, attempts) |> Process.sleep()
        do_lock(resource, ttl, value, attempts + 1, config)
      else
        log(config.log_level, "info", "<Redlock> failed to lock resource eventually: #{resource}")
        :error
      end
    end
  end

  defp do_extend(resource, value, ttl, config) do
    {number_of_success, quorum, validity} =
      lock_helper("extend", &extend_on_node/5, resource, value, ttl, config)

    if number_of_success >= quorum and validity > 0 do
      log(config.log_level, "debug", "<Redlock> extended lock for '#{resource}' successfully")
      :ok
    else
      log(config.log_level, "warning", "<Redlock> failed to extend lock resource: #{resource}")
      :error
    end
  end

  defp lock_helper(action, callback, resource, value, ttl, config) do
    started_at = now()
    servers = NodeChooser.choose(resource)
    quorum = div(length(servers), 2) + 1

    results =
      servers
      |> Enum.map(fn node ->
        case callback.(node, resource, value, ttl * 1000, config) do
          :ok ->
            log(
              config.log_level,
              "debug",
              "<Redlock> #{action}ed '#{resource}' successfully on node: #{node}, ttl: #{ttl}"
            )

            true

          {:error, _reason} ->
            false
        end
      end)

    number_of_success = results |> Enum.count(& &1)

    drift = ttl * config.drift_factor + 0.002
    elapsed_time = now() - started_at
    validity = ttl - elapsed_time / 1000.0 - drift

    log(
      config.log_level,
      "debug",
      "<Redlock> elapsed-#{elapsed_time} : success-#{number_of_success} : quorum-#{quorum}"
    )

    {number_of_success, quorum, validity}
  end

  defp calc_backoff(config, attempts) do
    Redlock.Util.calc_backoff(
      config.retry_interval_base,
      config.retry_interval_max,
      attempts
    )
  end

  defp lock_on_node(node, resource, value, ttl, config) do
    :poolboy.transaction(node, fn conn_keeper ->
      case ConnectionKeeper.connection(conn_keeper) do
        {:ok, redix} ->
          Command.lock(redix, resource, value, ttl, config)

        {:error, :not_found} = error ->
          log(config.log_level, "warning", "<Redlock> connection is currently unavailable")
          error
      end
    end)
  end

  def unlock_on_node(node, resource, value, config) do
    :poolboy.transaction(node, fn conn_keeper ->
      case ConnectionKeeper.connection(conn_keeper) do
        {:ok, redix} ->
          Command.unlock(redix, resource, value)

        {:error, :not_found} = error ->
          log(config.log_level, "warning", "<Redlock> connection is currently unavailable")
          error
      end
    end)
  end

  def extend_on_node(node, resource, value, ttl, config) do
    :poolboy.transaction(node, fn conn_keeper ->
      case ConnectionKeeper.connection(conn_keeper) do
        {:ok, redix} ->
          Command.extend(redix, resource, value, ttl, config)

        {:error, :not_found} = error ->

          log(config.log_level, "warning", "<Redlock> connection is currently unavailable")
          error
      end
    end)
  end
end
