defmodule KVServer.Command do
  @doc ~S"""
  Parsed the given `line` into a command.

  ## Examples

    iex> KVServer.Command.parse "CREATE shopping\r\n"
    {:ok, {:create, "shopping"}}

    iex> KVServer.Command.parse "CREATE   shopping   \r\n"
    {:ok, {:create, "shopping"}}

    iex> KVServer.Command.parse "PUT shopping milk 1\r\n"
    {:ok, {:put, "shopping", "milk", "1"}}

    iex> KVServer.Command.parse "GET shopping milk\r\n"
    {:ok, {:get, "shopping", "milk"}}

    iex> KVServer.Command.parse "DELETE shopping eggs\r\n"
    {:ok, {:delete, "shopping", "eggs"}}

  Unknown commands or commands with the wrong number of arguments
  return an error:

    iex> KVServer.Command.parse "UNKNOWN shopping eggs\r\n"
    {:error, :unknown_command}

    iex> KVServer.Command.parse "GET shopping\r\n"
    {:error, :unknown_command}
  """
  def parse(line) do
    case String.split(line) do
      ["CREATE", bucket] -> {:ok, {:create, bucket}}
      ["PUT", bucket, key, value] -> {:ok, {:put, bucket, key, value}}
      ["GET", bucket, key] -> {:ok, {:get, bucket, key}}
      ["DELETE", bucket, key] -> {:ok, {:delete, bucket, key}}
      _ -> {:error, :unknown_command}
    end
  end

  @doc """
  Runs the given command.
  """
  # use a function without a body to document what the arguments are.
  def run(command, registry)

  def run({:create, bucket}, registry) do
    KV.Registry.create(registry, bucket)
    {:ok, "OK\r\n"}
  end

  def run({:get, bucket, key}, registry) do
    lookup(bucket, registry, fn pid ->
      value = KV.Bucket.get(pid, key)
      {:ok, "#{value}\r\nOK\r\n"}
    end)
  end

  def run({:put, bucket, key, value}, registry) do
    lookup(bucket, registry, fn pid ->
      KV.Bucket.put(pid, key, value)
      {:ok, "OK\r\n"}
    end)
  end

  def run({:delete, bucket, key}, registry) do
    lookup(bucket, registry, fn pid ->
      KV.Bucket.delete(pid, key)
      {:ok, "OK\r\n"}
    end)
  end

  def lookup(bucket, registry, callback) do
    case KV.Registry.lookup(registry, bucket) do
      {:ok, pid} -> callback.(pid)
      :error -> {:error, :not_found}
    end
  end
end
