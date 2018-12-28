defmodule KVRegistryTest do
  @moduledoc """
  ## Shared state in tests
  We start one registry per test to ensure they are isolated. But `KV.BucketSupervisor`
  is registered globally, so will be shared between all tests. Should this matter?

  It depends. It is ok to rely on shared state as long as we depend only on a
  non-shared partition of this state. Although multiple registries may start buckets
  on the shared bucket supervisor, those buckets and registries are isolated from
  each other. We would only run into concurrency issues if we used a function like
  Supervisor.count_children(KV.BucketSupervisor) which would count all buckets from
  all registries, potentially giving different results when tests run concurrently.

  Since we have relied only on a non-shared partition of the bucket supervisor so far,
  we don’t need to worry about concurrency issues in our test suite. In case it ever
  becomes a problem, we can start a supervisor per test and pass it as an argument
  to the registry start_link function.
  """
  use ExUnit.Case, async: true

  setup do
    # calling start_supervised instead of calling KV.Registry.start_link/1
    # directly means that ExUnit can guarantee that the registry process is
    # shut down before the next test starts
    registry = start_supervised!(KV.Registry)
    %{registry: registry}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)
    # should error because removed
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes buckets on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    # stop the bucket with non-normal reason
    Agent.stop(bucket, :shutdown)
    # should error because removed
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
end
