defmodule KV.Bucket do
  # restart: :temporary means a bucket that fails will not be restarted so we can
  # safely remove it from the registry without getting a build up of stale resources
  # in the `DynamicSupervisor`
  #
  # Why use a supervisor if it never restarts its children? It happens that
  # supervisors provide more than restarts, they are also responsible to guarantee
  # proper startup and shutdown, especially in case of crashes in a supervision tree.
  #
  use Agent, restart: :temporary

  @moduledoc """
  Bag of holding for distributed Key-Value application

  The app is structured as a "supervision tree" (supervisors supervising other
  supervisors):

         KV.Supervisor (`use Supervisor`)
           |--- starts ----> DynamicSupervisor (named KV.BucketSupervisor)
           |--- starts ----> Registry (`use GenServer`)
                               |--- starts ----> KV.Bucket (`use Agent`)
                                                /    ||    \
                                          Bucket   Bucket  ... Bucket
  """

  @doc """
  Starts a new bucket
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` into the `bucket`
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end

  @doc """
  Deletes a key from the bucket
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, fn dict ->
      Map.pop(dict, key)
    end)
  end
end
