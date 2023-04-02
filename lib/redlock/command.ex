defmodule Redlock.Command do
  require Logger

  @unlock_script ~S"""
  if redis.call("get",KEYS[1]) == ARGV[1] then
    return redis.call("del",KEYS[1])
  else
    return 0
  end
  """

  @extend_script ~S"""
  if redis.call("get",KEYS[1]) == ARGV[1] then
    return redis.call("pexpire",KEYS[1],ARGV[2],"GT")
  else
    return redis.error_reply('NOT LOCKED')
  end
  """

  def unlock_hash() do
    :crypto.hash(:sha, @unlock_script) |> Base.encode16() |> String.downcase()
  end

  def extend_hash() do
    :crypto.hash(:sha, @extend_script) |> Base.encode16() |> String.downcase()
  end

  def install_scripts(redix) do
    with {:ok, unlock_val} <- Redix.command(redix, ["SCRIPT", "LOAD", @unlock_script]),
         {:ok, extend_val} <- Redix.command(redix, ["SCRIPT", "LOAD", @extend_script]) do
      if unlock_val == unlock_hash() and extend_val == extend_hash() do
        {:ok, unlock_val, extend_val}
      else
        {:error, :hash_mismatch}
      end
    else
      error -> error
    end
  end

  def lock(redix, resource, value, ttl) do
    case Redix.command(redix, ["SET", resource, value, "NX", "PX", to_string(ttl)]) do
      {:ok, "OK"} ->
        :ok

      {:ok, nil} ->
        Logger.info("<Redlock> resource:#{resource} is already locked")
        {:error, :already_locked}

      other ->
        Logger.error("<Redlock> failed to execute redis SET: #{inspect(other)}")
        {:error, :system_error}
    end
  end

  def unlock(redix, resource, value) do
    Redix.command(redix, ["EVALSHA", unlock_hash(), to_string(1), resource, value])
  end

  def extend(redix, resource, value, ttl) do
    case Redix.command(redix, ["EVALSHA", extend_hash(), to_string(1), resource, value, ttl]) do
      {:ok, _} ->
        :ok

      other ->
        Logger.info("<Redlock> Unable to extend resource: #{resource}. #{inspect(other)}")
        {:error, :cannot_extend}
    end
  end
end
