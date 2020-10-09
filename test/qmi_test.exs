defmodule QmiTest do
  use ExUnit.Case
  doctest Qmi

  test "greets the world" do
    assert Qmi.hello() == :world
  end
end
