defmodule RacebookTest do
  use ExUnit.Case
  doctest Racebook

  test "greets the world" do
    assert Racebook.hello() == :world
  end
end
