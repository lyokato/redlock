defmodule Redlock.UtilTest do
  use ExUnit.Case

  alias Redlock.Util

  describe "calc_backoff/3" do
    test "returns the backoff when the attemp_counts are high enough to overflow" do
      base_ms = 300
      max_ms = 3000
      attempt_counts = 1016

      assert is_number(Util.calc_backoff(base_ms, max_ms, attempt_counts))
    end
  end
end
