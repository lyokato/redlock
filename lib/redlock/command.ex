defmodule Redlock.Command do

  @helper_script ~S"""
if redis.call("get",KEYS[1]) == ARGV[1] then
  return redis.call("del",KEYS[1])
else
  return 0
end
  """

  def helper_hash() do
    :crypto.hash(:sha, @helper_script) |> Base.encode16 |> String.downcase
  end

  def install_script(redix) do
    case Redix.command(redix, ["SCRIPT", "LOAD", @helper_script]) do

      {:ok, val} ->
        if val == helper_hash() do
          {:ok, val}
        else
          {:error, :hash_mismatch}
        end

      other -> other

    end
  end

  def lock(redix, resource, value, ttl) do
    Redix.command(redix, ["SET", resource, value, "NX", "PX", ttl * 1000])
  end

  def unlock(redix, resource, value) do
    Redix.command(redix, ["EVALSHA", helper_hash(), 1, resource, value])
  end

end
