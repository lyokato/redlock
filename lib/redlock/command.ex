defmodule Redlock.Command do
  require Logger

  @helper_script ~S"""
  if redis.call("get",KEYS[1]) == ARGV[1] then
    return redis.call("del",KEYS[1])
  else
    return 0
  end
  """

  def helper_hash() do
    :crypto.hash(:sha, @helper_script) |> Base.encode16() |> String.downcase()
  end

  def install_script(redix) do
    case Redix.command(redix, ["SCRIPT", "LOAD", @helper_script]) do
      {:ok, val} ->
        if val == helper_hash() do
          {:ok, val}
        else
          {:error, :hash_mismatch}
        end

      other ->
        other
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
    Redix.command(redix, ["EVALSHA", helper_hash(), to_string(1), resource, value])
  end
end
