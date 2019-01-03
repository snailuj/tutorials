defmodule KV.RouterTest do
  use ExUnit.Case, async: true

  # In order to run this test we need to have two nodes running. From apps/kv, start the node named
  # `bar` which is going to be used by the tests
  #
  #   $ iex --sname bar -S mix
  #
  # And then run tests with:
  #
  #   $ elixir --sname foo -S mix test
  #
  # writing @tag :distributed is equiv to @tag distributed: true
  @tag :distributed
  test "route requests across nodes" do
    # return the name of the node based on the bucket name "hello" -- should be "foo"
    # (Kernel.node/0 is a built-in that returns the node name)
    assert KV.Router.route("hello", Kernel, :node, []) == :foo@scorpio

    assert KV.Router.route("world", Kernel, :node, []) == :bar@scorpio
  end

  test "raises on unknown entries" do
    assert_raise RuntimeError, ~r/could not find entry/, fn ->
      KV.Router.route(<<0>>, Kernel, :node, [])
    end
  end
end
