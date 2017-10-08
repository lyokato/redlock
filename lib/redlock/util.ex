defmodule Redlock.Util do

  def random_value() do
    SecureRandom.hex(40)
  end

  def now() do
    System.system_time(:milli_seconds)
  end

end
