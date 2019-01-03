defmodule KV.Router do
  @doc """
  Dispatch the given `mod`, `fun`, `args` request to the appropriate node
  based on the `bucket`.

  Distributed tasks are exactly the same as regular supervised tasks. The only
  difference is that we pass the node name when spawning the task on the
  supervisor.
  """

  def route(bucket, mod, fun, args) do
    # Get the first byte of the binary bucket name
    first = :binary.first(bucket)

    # Try to find an entry in the table() or raise
    entry =
      Enum.find(table(), fn {enum, _node} ->
        first in enum
      end) || no_entry_error(bucket)

    # If the second elem of `entry` holds the name of the current node
    if elem(entry, 1) == node() do
      # Run the function
      apply(mod, fun, args)
    else
      # Otherwise, the second elem refers to our "downstream" node
      # So we refer on by spawning `route/4` as an async task on that node
      {KV.RouterTasks, elem(entry, 1)}
      |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
      # Read from it immediately (blocks until done)
      |> Task.await()
    end
  end

  defp no_entry_error(bucket) do
    raise "could not find entry for #{inspect bucket} in table #{inspect table()}"
  end

  @doc """
  The routing table.
  """
  def table do
    # hardcoded form
    # [{?a..?m, :foo@scorpio}, {?n..?z, :bar@scorpio}]

    # Configured form, fetched from `KV.MixProject.application/0` in `mix.exs`
    Application.fetch_env!(:kv, :routing_table)
  end
end
