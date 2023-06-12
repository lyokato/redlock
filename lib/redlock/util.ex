defmodule Redlock.Util do
  require Logger

  @max_attempt_counts 1000

  def random_value() do
    SecureRandom.hex(40)
  end

  def now() do
    System.system_time(:millisecond)
  end

  def calc_backoff(base_ms, max_ms, attempt_counts) do
    # Avoid max.pow to overflow
    safe_attempt_counts = min(@max_attempt_counts, attempt_counts)

    max =
      (base_ms * :math.pow(2, safe_attempt_counts))
      |> min(max_ms)
      |> trunc
      |> max(base_ms + 1)

    :rand.uniform(max - base_ms) + base_ms
  end

  def log(_level, "error", msg), do: Logger.error(msg)

  def log(level, "warning", msg) when level in ["debug", "info", "warning"],
    do: Logger.warning(msg)

  def log(level, "info", msg) when level in ["debug", "info"], do: Logger.info(msg)

  def log("debug", "debug", msg), do: Logger.debug(msg)

  def log(_config_level, _log_level, _msg), do: :ok
end
