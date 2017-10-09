defmodule Redlock.Executor do

  require Logger

  def lock(resource, ttl) do # TTL = seconds
    do_lock(resource, ttl, Redlock.Util.random_value(), 0, Redlock.Config.get())
  end

  def unlock(resource, value) do
    config = Redlock.Config.get()
    config.servers |> Enum.each(fn node ->
      case unlock_on_node(node, resource, value) do

        {:ok, _} ->
          Logger.debug "<Redlock> unlocked successfully on node: #{node}"
          :ok

        {:error, reason} ->
          Logger.error "<Redlock> failed to execute redis-unlock-command: #{inspect reason}"
          :error

      end
    end)
  end

  defp do_lock(resource, _ttl, _value, retry, %{max_retry: max_retry})
    when retry >= max_retry do
    Logger.error "<Redlock> failed to lock resource eventually: #{resource}"
    :error
  end

  defp do_lock(resource, ttl, value, retry, config) do

    started_at = Redlock.Util.now()

    results = config.servers |> Enum.map(fn node ->
      case lock_on_node(node, resource, value, ttl * 1000) do

        :ok ->
          Logger.debug "<Redlock> locked successfully on node: #{node}"
          true

        {:error, reason} ->
          Logger.warn "<Redlock> failed to execute redis-lock-command: #{inspect reason}"
          false

      end
    end)

    number_of_success = results |> Enum.count(&(&1))

    drift    = ttl * config.drift_factor + 0.002
    validity = ttl - ((Redlock.Util.now() - started_at) / 1000.0) - drift

    Logger.debug "<Redlock> success-#{number_of_success} : quorum-#{config.quorum}"

    if number_of_success >= config.quorum and validity > 0 do

      Logger.debug "<Redlock> created lock for #{resource} successfully"
      {:ok, value}

    else

      Logger.warn "<Redlock> failed to lock:#{resource}, retry after interval"
      Process.sleep(config.retry_interval)
      do_lock(resource, ttl, value, retry + 1, config)

    end

  end

  defp lock_on_node(node, resource, value, ttl) do
    :poolboy.transaction(node, fn conn_keeper ->
      case Redlock.ConnectionKeeper.connection(conn_keeper) do

        {:ok, redix} ->
          Redlock.Command.lock(redix, resource, value, ttl)

        {:error, :not_found} = error -> error

      end
    end)
  end

  def unlock_on_node(node, resource, value) do
    :poolboy.transaction(node, fn conn_keeper ->
      case Redlock.ConnectionKeeper.connection(conn_keeper) do

        {:ok, redix} ->
          Redlock.Command.unlock(redix, resource, value)

        {:error, :not_found} = error -> error

      end
    end)
  end

end

