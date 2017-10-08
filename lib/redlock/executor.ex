defmodule Redlock.Executor do

  use GenServer
  require Logger

  @default_drift_factor 0.01
  @default_max_retry 5
  @default_retry_interval 300

  defstruct quorum:       0,
            drift_factor: 0,
            servers:      [],
            max_retry:    0,
            retry_interval: 300

  def lock(resource, ttl) do # TTL = seconds
    GenServer.call(__MODULE__, {:lock, resource, ttl})
  end

  def unlock(resource, value) do
    GenServer.call(__MODULE__, {:unlock, resource, value})
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do

    servers        = Keyword.fetch!(opts, :servers)
    drift_factor   = Keyword.get(opts, :drift_factor, @default_drift_factor)
    max_retry      = Keyword.get(opts, :max_retry, @default_max_retry)
    retry_interval = Keyword.get(opts, :retry_interval, @default_retry_interval)

    {:ok, %__MODULE__{quorum:         div(length(servers), 2) + 1,
                      max_retry:      max_retry,
                      drift_factor:   drift_factor,
                      retry_interval: retry_interval,
                      servers:        servers}}

  end

  def handle_call({:lock, resource, ttl}, _from, state) do
    case do_lock(resource, ttl, Redlock.Util.random_value(), 0, state) do

      {:ok, value} ->
        {:reply, {:ok, value}, state}

      other ->
        {:reply, other, state}

    end
  end

  def handle_call({:unlock, resource, value}, _from, state) do
    do_unlock(resource, value, state)
    {:reply, :ok, state}
  end


  def terminate(_reason, _state), do: :ok

  defp do_lock(resource, _ttl, _value, retry, %{max_retry: max_retry})
    when retry >= max_retry do
    Logger.error "<Redlock> failed to lock resource eventually: #{resource}"
    :error
  end

  defp do_lock(resource, ttl, value, retry, state) do

    started_at = Redlock.Util.now()

    results = state.servers |> Enum.map(fn node ->
      case lock_on_node(node, resource, value, ttl * 1000) do

        {:ok, _} ->
          Logger.debug "<Redlock> locked successfully on node: #{node}"
          true

        {:error, reason} ->
          Logger.error "<Redlock> failed to execute redis-lock-command: #{reason}"
          false

      end
    end)

    number_of_success = results |> Enum.count(&(&1))

    drift    = ttl * state.drift_factor + 0.002
    validity = ttl - ((Redlock.Util.now() - started_at) / 1000.0) - drift

    if number_of_success >= state.quorum and validity > 0 do

      Logger.debug "<Redlock> create lock for #{resource} successfully"
      {:ok, value}

    else

      Logger.warn "<Redlock> failed to lock:#{resource}, retry after interval"
      Process.sleep(state.retry_interval)
      do_lock(resource, ttl, value, retry + 1, state)

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

  defp do_unlock(resource, value, state) do
    state.servers |> Enum.each(fn node ->
      case unlock_on_node(node, resource, value) do

        {:ok, _} ->
          Logger.debug "<Redlock> unlocked successfully on node: #{node}"
          :ok

        {:error, reason} ->
          Logger.error "<Redlock> failed to execute redis-unlock-command: #{reason}"
          :error

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

