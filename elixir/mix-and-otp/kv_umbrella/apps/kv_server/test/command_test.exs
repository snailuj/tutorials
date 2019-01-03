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

defmodule KVServer.CommandIntegrationTest do
  @moduledoc """
  Integration tests that rely on a global server name to exercise the
  whole stack from the TCP server to the bucket.

  We have set `async: false` on this module because that way a single Registry
  will be created for the whole test Case. Furthermore, in order to guarantee
  our test is always in a clean state, we stop and start the :kv application
  before each test. In fact, stopping the :kv application even prints a warning
  on the terminal.

  Our integration tests will rely on global state and must be synchronous.
  With integration tests, we get coverage on how the components in our
  application work together at the cost of test performance. They are
  typically used to test the main flows in your application. For example,
  we should avoid using integration tests to test an edge case in our command
  parsing implementation.

  With this simple integration test, we start to see why integration tests may
  be slow. Not only this test cannot run asynchronously, it also requires the
  expensive setup of stopping and starting the :kv application.
  """

  use ExUnit.Case, async: false

  # avoid printing warning when :kv is stopped for each test. In case the test
  # fails, the captured log will be printed alongside the ExUnit report
  @moduletag :capture_log

  setup do
    Application.stop(:kv)
    :ok = Application.start(:kv)
  end

  setup do
    opts = [:binary, packet: :line, active: false]
    # It is worth noting that, as with ETS tables and linked processes, there
    # is no need to close the socket. Once the test process exits, the socket is
    # automatically closed.
    {:ok, socket} = :gen_tcp.connect('localhost', 4040, opts)
    %{socket: socket}
  end

  test "server interaction", %{socket: socket} do
    assert send_and_recv(socket, "UNKNOWN shopping\r\n") == "UNKNOWN COMMAND\r\n"

    assert send_and_recv(socket, "GET shopping eggs\r\n") == "NOT FOUND\r\n"

    assert send_and_recv(socket, "CREATE shopping\r\n") == "OK\r\n"

    assert send_and_recv(socket, "PUT shopping eggs 3\r\n") == "OK\r\n"

    # GET returns two lines
    assert send_and_recv(socket, "GET shopping eggs\r\n") == "3\r\n"
    assert send_and_recv(socket, "") == "OK\r\n"

    assert send_and_recv(socket, "DELETE shopping eggs\r\n") == "OK\r\n"

    # GET returns two lines
    assert send_and_recv(socket, "GET shopping eggs\r\n") == "\r\n"
    assert send_and_recv(socket, "") == "OK\r\n"
  end

  defp send_and_recv(socket, command) do
    :ok = :gen_tcp.send(socket, command)
    {:ok, data} = :gen_tcp.recv(socket, 0, 1000)

    data
  end
end
