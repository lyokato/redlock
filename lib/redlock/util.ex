defmodule Redlock.Util do

  def random_value() do
    SecureRandom.hex(40)
  end

  def now() do
    System.system_time(:millisecond)
  end

  def calc_backoff(base_ms, max_ms, attempt_counts) do
    max =
      base_ms * :math.pow(2, attempt_counts)
      |> min(max_ms)
      |> trunc
      |> max(base_ms + 1)

    :rand.uniform(max - base_ms) + base_ms
  end

end
