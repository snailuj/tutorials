defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  #runs before each test
  setup do
    %{bucket: start_supervised!(KV.Bucket)}
  end

  #the test context is passed to each test. Here we destructure `bucket`
  #out of the context as it's all we're interested in.
  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "deletes values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.delete(bucket, "milk") == 3
    assert KV.Bucket.get(bucket, "milk") == nil
  end

  test "buckets are temporary" do
    assert Supervisor.child_spec(KV.Bucket, []).restart == :temporary
  end
end
