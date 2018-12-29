defmodule KVServer.CommandTest do
  use ExUnit.Case, async: true
  doctest KVServer.Command

  setup context do
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "run create bucket", %{registry: registry} do
    {:ok, command} = KVServer.Command.parse("CREATE shopping")
    assert {:create, "shopping"} = command
    assert KVServer.Command.run(command, registry) == {:ok, "OK\r\n"}
  end
end
