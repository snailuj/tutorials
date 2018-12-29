defmodule KVServer do
  require Logger

  @moduledoc """
  A TCP server, in broad strokes, performs the following steps:

    * Listens to a port until the port is available and it gets hold of the socket
    * Waits for a client connection on that port and accepts it
    * Reads the client request and writes a response back
  """

  def accept(port) do
    # The options below mean:
    #
    # 1. `:binary` - receives data as binaries (instead of lists)
    # 2. `packet: :line` - receives data line by line
    # 3. `active: false` - blocks on `:gen_tcp.recv/2` until data is available
    # 4. `reuseaddr: true` - allows us to reuse the address if the listener crashes
    #
    {:ok, socket} =
      :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])

    Logger.info("Accepting connections on port #{port}")
    loop_acceptor(socket)
  end

  defp loop_acceptor(socket) do
    {:ok, client} = :gen_tcp.accept(socket)

    # Tasks started by Task.Supervisor have the :temporary restart strategy by default
    # which is fine for failed connections to a client
    {:ok, pid} =
      Task.Supervisor.start_child(
        KVServer.TaskSupervisor,
        fn -> serve(client) end
      )

    # This makes the child process the “controlling process” of the client socket. If we didn’t
    # do this, the acceptor would bring down all the clients if it crashed because sockets would
    # be tied to the process that accepted them (which is the default behaviour).
    :ok = :gen_tcp.controlling_process(client, pid)

    # recursively accept connections
    loop_acceptor(socket)
  end

  defp serve(client) do
    client
    |> read_line
    |> write_line(client)

    # recursively read from client
    serve(client)
  end

  defp read_line(client) do
    # will block until data is received because active: false was specified in `KVServer.accept/1`
    {:ok, data} = :gen_tcp.recv(client, 0)
    data
  end

  defp write_line(line, client) do
    :gen_tcp.send(client, line)
  end
end
