defmodule TaskManagerTest do
  use ExUnit.Case
  doctest TaskManager

  test "greets the world" do
    assert TaskManager.hello() == :world
  end
end
