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

  ## Task entry function, spawned for each `:gen_tcp.accept/1`
  defp serve(client) do
    # msg =
    #   case read_line(client) do
    #     {:ok, data} ->
    #       case KVServer.Command.parse(data) do
    #         {:ok, command} ->
    #           KVServer.Command.run(command)
    #         # parse error, found via destructuring but return the whole tuple by assigning to `err`
    #         {:error, _} = err -> err
    #       end
    #     # error in `read_line/1`
    #     {:error, _} = err -> err
    #   end
    # Can replace the nested `case` statements above with a `with` statement:
    # retrieves the value returned by the right-side of <- and matches it against
    # the pattern on the left side. If the value matches the pattern, `with` moves on to the
    # next expression. In case there is no match, the non-matching value is assigned to `msg`

    msg =
      with {:ok, data} <- read_line(client),
           {:ok, command} <- KVServer.Command.parse(data),
           do: KVServer.Command.run(command, KV.Registry)

    write_line(client, msg)
    # recursively read from client
    serve(client)
  end

  defp read_line(client) do
    # will block until data is received because active: false was specified in `KVServer.accept/1`
    :gen_tcp.recv(client, 0)
  end

  defp write_line(client, {:ok, text}) do
    :gen_tcp.send(client, text)
  end

  defp write_line(client, {:error, :unknown_command}) do
    # Known error. Write to client
    :gen_tcp.send(client, "UNKNOWN COMMAND\r\n")
  end

  defp write_line(client, {:error, :not_found}) do
    # Bucket not found
    :gen_tcp.send(client, "NOT FOUND\r\n")
  end

  defp write_line(client, {:error, :closed}) do
    # The connection was closed. Exit politely
    exit(:shutdown)
  end

  defp write_line(client, {:error, error}) do
    # Unknown error. Write to client and exit.
    :gen_tcp.send(client, "ERROR\r\n")
    exit(error)
  end
end
