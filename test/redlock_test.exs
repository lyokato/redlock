defmodule RedlockTest do
  use ExUnit.Case

  test "transaction" do
    key = "foo"

    result =
      Redlock.transaction(key, 5, fn ->
        {:ok, 2}
      end)

    assert result == {:ok, 2}
  end

  test "confliction" do
    key = "same"

    # lock with enough duration
    {:ok, mutex} = Redlock.lock(key, 20)

    # try to lock, and do some retry internally
    result1 =
      Redlock.transaction(key, 5, fn ->
        {:ok, 2}
      end)

    # should fail eventually
    assert result1 == {:error, :lock_failure}

    assert Redlock.unlock(key, mutex) == :ok

    result2 =
      Redlock.transaction(key, 1, fn ->
        {:ok, 2}
      end)

    assert result2 == {:ok, 2}
  end

  test "expiration" do
    key = "bar"

    # this lock automatically expired in 1 seconds.
    {:ok, _mutex} = Redlock.lock(key, 1)

    # try to lock, and do some retry internally.
    # the retry-configuration has enough interval.
    result1 =
      Redlock.transaction(key, 5, fn ->
        {:ok, 2}
      end)

    # should success eventually
    assert result1 == {:ok, 2}
  end
end
