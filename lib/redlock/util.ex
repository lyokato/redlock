defmodule Redlock.Util do
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
end
