defmodule Redlock.Config do

  use GenServer
  require Logger

  @default_drift_factor 0.01
  @default_max_retry 5
  @default_retry_interval 300

  defstruct drift_factor:     0,
            max_retry:        0,
            retry_interval: 300

  def get() do
    GenServer.call(__MODULE__, :get)
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def init(opts) do

    drift_factor   = Keyword.get(opts, :drift_factor, @default_drift_factor)
    max_retry      = Keyword.get(opts, :max_retry, @default_max_retry)
    retry_interval = Keyword.get(opts, :retry_interval, @default_retry_interval)

    #{:ok, %__MODULE__{quorum:         div(length(servers), 2) + 1,
    {:ok, %__MODULE__{max_retry:      max_retry,
                      drift_factor:   drift_factor,
                      retry_interval: retry_interval}}
  end

  def handle_call(:get, _from, state) do
    {:reply, state, state}
  end

  def terminate(_reason, _state), do: :ok

end
