defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  test "stores values by key" do
    {:ok, bucket} = start_supervised(KV.Bucket)
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end

  test "stores values by key on a named process", config do
    {:ok, _} = start_supervised({KV.Bucket, name: config.test})
    assert KV.Bucket.get(config.test, "milk") == nil

    KV.Bucket.put(config.test, "milk", 3)
    assert KV.Bucket.get(config.test, "milk") == 3
  end

  test "deletes a key and returns the current value", config do
    {:ok, _} = start_supervised({KV.Bucket, name: config.test})

    KV.Bucket.put(config.test, "milk", 3)
    assert KV.Bucket.delete(config.test, "milk") == 3
  end

  test "subscribe to puts and deletes", config do
    {:ok, bucket} = start_supervised({KV.Bucket, name: config.test})
    KV.Bucket.subscribe(bucket)

    KV.Bucket.put(bucket, "milk", 3)
    assert_receive {:put, "milk", 3}

    # Also check if it works from another process
    spawn_link(fn -> KV.Bucket.delete(bucket, "milk") end)
    assert_receive {:delete, "milk"}
  end

  test "counts subscribers", config do
    {:ok, bucket} = start_supervised({KV.Bucket, name: config.test})

    assert KV.Bucket.count_subscribers(bucket) == 0

    KV.Bucket.subscribe(bucket)

    assert KV.Bucket.count_subscribers(bucket) == 1
  end
end
