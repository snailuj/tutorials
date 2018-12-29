defmodule KV.Registry do
  use GenServer

  @moduledoc """
  Defines a Client/Server API for creating and looking up `KV.Bucket`s by name

  Refactored to use ETS caching! Before that, KV.Registry.lookup/2 sent requests
  to the server, but now it reads directly from the ETS table, which is shared
  across all processes. That’s the main idea behind the refactor.

  In order for this to work, the created ETS table needs to have access :protected
  (the default), so all clients can read from it, while only the KV.Registry
  process writes to it. We have also set read_concurrency: true when starting
  the table, optimizing the table for the common scenario of concurrent read
  operations.
  """

  ## Client API

  @doc """
  Starts the registry with the given options.

  `name` is always required
  """
  def start_link(opts) do
    # starts a GenServer process linked to the current process
    # first arg is the code module where the server callbacks are impld
    # (here we use the magic__MODULE__ to set it up with the current module)
    # second arg is given to `init`

    server = Keyword.fetch!(opts, :name)
    # pass `name` to `init`
    GenServer.start_link(__MODULE__, server, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.
  Requests are often specified as tuples, like this, in order to provide
  more than one “argument” in that first argument slot. It’s common to
  specify the action being requested as the first element of a tuple, and
  arguments for that action in the remaining elements. Note that the
  requests must match the first argument to handle_call/3 or handle_cast/2.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    # Before using ETS, we did a GenServer.call() as in the below:
    # GenServer.call(server, {:lookup, name})

    # We now use ETS caching without accessing server
    case :ets.lookup(server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  ## Server Callbacks
  # The server keeps track of `KV.Bucket`s by two mappings:
  #
  # %{name: pid} = names (for returning bucket PIDs from `handle_call`)
  # %{monitor ref: name} = refs (for tracking when buckets fail and removing them)
  #
  # There are two types of requests you can send to a GenServer: calls and
  # casts. Calls are synchronous and the server must send a response back
  # to such requests. Casts are asynchronous and the server won’t send a
  # response back.

  # called when GenServer.start_link is called when bound to this module
  def init(table) do
    # second arg is current state
    # Previous to ETS we used a map to store names, now we use a table
    table |> IO.inspect(label: "table name: ")
    names = :ets.new(table, [:named_table, read_concurrency: true])
    IO.inspect(names, label: "names: ")
    refs  = %{}
    {:ok, {names, refs}}
  end

  # Previous to ETS, we had the following function defined:
  #
  # Handles `request` as a synchronous call to this server, who's state is
  # currently equal to `state`, `from` a particular client (which will receive
  # the response).
  #
  #  def handle_call(request, from, names)
  #  def handle_call({:lookup, name}, _from, {names, _} = state) do
  #    # :reply indicates that the GenServer should send a response
  #    # The second element is the data to send to the client
  #    # The third element is the new server state
  #    {:reply, Map.fetch(names, name), state}
  #  end

  @doc """
  Handles `request` as a synchronous call to this server, who's state is currently equal to
  `names`, `from` a particular client (which will receive the response)
  """
  def handle_call(request, from, names)

  def handle_call({:create, name}, _from, {names, refs}) do
    # Read and write to ETS instead of the map
    case lookup(names, name) do
      {:ok, pid} ->
        # already exists
        {:reply, pid, {names, refs}}

      :error ->
        # not found, create
        {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        refs = refs |> Map.put(Process.monitor(pid), name)
        names |> :ets.insert({name, pid})
        {:reply, pid, {names, refs}}
    end
  end

  # Previous to ETS caching, the implementation looked like:
  # def handle_cast({:create, name}, {names, refs} = state) do
  #   # note that in a real-world app we would probably have implemented create()
  #   # as a synchronous call -- this is just for illustrating how to do casts
  #   if Map.has_key?(names, name) do
  #     {:noreply, state}
  #   else
  #     # `KV.BucketSupervisor` is the name we gave our `DynamicSupervisor` process
  #     # in `KV.Supervisor.init`, the second param is the child to be started
  #     # when a bucket terminates (e.g. due to a bug), the supervisor will start a
  #     # new one in its place
  #     {:ok, pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)

  #     {:noreply,
  #      {
  #        names |> Map.put(name, pid),
  #        refs |> Map.put(Process.monitor(pid), name)
  #      }}
  #   end
  # end

  # Callback that handles supervision messages
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    # get the name for `ref` and replace `refs` with a new map minus `ref`
    {name, refs} = refs |> Map.pop(ref)
    :ets.delete(names, name)
    # Previous to ETS caching, we would replace `names` with a new map minus `name`:
    # names = names |> Map.delete(name)
    {:noreply, {names, refs}}
  end

  # catchall clause so we don't get "no matching function clause" errors from
  # unexpected info messages (`handle_info` is called for any message that is not
  # an explicit `cast` or `call`, including the generic `send/2`)
  def handle_info(_msg, state) do
    {:noreply, state}
  end
end
