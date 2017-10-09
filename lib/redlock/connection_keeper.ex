defmodule Redlock.ConnectionKeeper do

  @default_port 6379
  @default_reconnection_interval 5_000

  require Logger

  use GenServer

  @spec connection(pid) :: {:ok, pid} | {:error, :not_found}
  def connection(pid) do
    GenServer.call(pid, :get_connection)
  end

  defstruct host: "",
            port: nil,
            redix: nil,
            reconnection_interval: 0

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end

  def init(opts) do
    Process.flag(:trap_exit, true)
    send self(), :connect
    {:ok, new(opts)}
  end

  def handle_info(:connect, %{host: host, port: port}=state) do

    case Redix.start_link([host: host, port: port],
                          [sync_connect: true, exit_on_disconnection: true]) do

      {:ok, pid} ->
        Logger.debug "<Redlock.ConnectionKeeper:#{host}:#{port}> connected to Redis"
        install_script(pid, state)

      other ->
        Logger.error "<Redlock.ConnectionKeeper:#{host}:#{port}> failed to connect, try to re-connect after interval: #{inspect other}"
        Process.send_after(self(), :connect, state.reconnection_interval)
        {:noreply, %{state| redix: nil}}

    end

  end

  def handle_info({:EXIT, pid, _reason}, %{host: host, port: port, redix: pid}=state) do
    Logger.error "<Redlock.ConnectionKeeper:#{host}:#{port}> seems to be disconnected, try to re-connect"
    Process.send_after(self(), :connect, state.reconnection_interval)
    {:noreply, %{state| redix: nil}}
  end

  def handle_info(_info, state) do
    {:noreply, state}
  end

  def handle_call(:get_connection, _from, %{redix: nil}=state) do
    {:reply, {:error, :not_found}, state}
  end
  def handle_call(:get_connection, _from, %{redix: redix}=state) do
    {:reply, {:ok, redix}, state}
  end

  def terminate(_reason, _state), do: :ok

  defp new(opts) do

    host = Keyword.fetch!(opts, :host)
    port = Keyword.get(opts, :port, @default_port)
    reconnection_interval = Keyword.get(opts, :reconnection_interval, @default_reconnection_interval)

    %__MODULE__{host: host,
                port: port,
                redix: nil,
                reconnection_interval: reconnection_interval}

  end

  defp install_script(pid, %{host: host, port: port}=state) do
    case Redlock.Command.install_script(pid) do

      {:ok, _val} ->
        {:noreply, %{state| redix: pid}}

      other ->
        Logger.warn "<Redlock:ConnectionKeeper:#{host}:#{port}> failed to install script: #{inspect other}"
        Redix.stop(pid)
        {:noreply, %{state| redix: nil}}
    end
  end

end
