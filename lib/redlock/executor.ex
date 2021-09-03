defmodule Redlock.Executor do
  require Logger

  alias Redlock.Command
  alias Redlock.ConnectionKeeper
  alias Redlock.NodeChooser

  import Redlock.Util, only: [now: 0, random_value: 0]

  # TTL = seconds
  def lock(resource, ttl) do
    do_lock(resource, ttl, random_value(), 0, FastGlobal.get(:redlock_conf))
  end

  def unlock(resource, value) do
    debug_logs_enabled = FastGlobal.get(:redlock_conf).show_debug_logs

    NodeChooser.choose(resource)
    |> Enum.each(fn node ->
      case unlock_on_node(node, resource, value) do
        {:ok, _} ->
          debug_log(
            debug_logs_enabled,
            "<Redlock> unlocked '#{resource}' successfully on node: #{node}"
          )

          :ok

        {:error, reason} ->
          Logger.error("<Redlock> failed to execute redis-unlock-command: #{inspect(reason)}")
          :error
      end
    end)
  end

  defp do_lock(resource, _ttl, _value, retry, %{max_retry: max_retry})
       when retry >= max_retry do
    Logger.warn("<Redlock> failed to lock resource eventually: #{resource}")
    :error
  end

  defp do_lock(resource, ttl, value, attempts, config) do
    started_at = now()
    servers = NodeChooser.choose(resource)
    quorum = div(length(servers), 2) + 1

    results =
      servers
      |> Enum.map(fn node ->
        case lock_on_node(node, resource, value, ttl * 1000) do
          :ok ->
            debug_log(
              config.show_debug_logs,
              "<Redlock> locked '#{resource}' successfully on node: #{node}"
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

    debug_log(
      config.show_debug_logs,
      "<Redlock> elapsed-#{elapsed_time} : success-#{number_of_success} : quorum-#{quorum}"
    )

    if number_of_success >= quorum and validity > 0 do
      debug_log(
        config.show_debug_logs,
        "<Redlock> created lock for '#{resource}' successfully"
      )

      {:ok, value}
    else
      Logger.info("<Redlock> failed to lock '#{resource}', retry after interval")
      calc_backoff(config, attempts) |> Process.sleep()
      do_lock(resource, ttl, value, attempts + 1, config)
    end
  end

  defp calc_backoff(config, attempts) do
    Redlock.Util.calc_backoff(
      config.retry_interval_base,
      config.retry_interval_max,
      attempts
    )
  end

  defp lock_on_node(node, resource, value, ttl) do
    :poolboy.transaction(node, fn conn_keeper ->
      case ConnectionKeeper.connection(conn_keeper) do
        {:ok, redix} ->
          Command.lock(redix, resource, value, ttl)

        {:error, :not_found} = error ->
          Logger.warn("<Redlock> connection is currently unavailable")
          error
      end
    end)
  end

  def unlock_on_node(node, resource, value) do
    :poolboy.transaction(node, fn conn_keeper ->
      case ConnectionKeeper.connection(conn_keeper) do
        {:ok, redix} ->
          Command.unlock(redix, resource, value)

        {:error, :not_found} = error ->
          Logger.warn("<Redlock> connection is currently unavailable")
          error
      end
    end)
  end

  defp debug_log(false, _msg), do: :ok
  defp debug_log(true, msg), do: Logger.debug(msg)
end
