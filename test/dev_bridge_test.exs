defmodule DevBridgeTest do
  use ExUnit.Case
  doctest DevBridge

  @pipe_filename "test_pipe"

  setup do
    _ = File.rm(@pipe_filename)
    {"", 0} = System.cmd("mkfifo", [@pipe_filename])

    on_exit(fn -> File.rm!(@pipe_filename) end)

    {:ok, dev1} = start_supervised(DevBridge, id: :dev1)
    {:ok, dev2} = start_supervised(DevBridge, id: :dev2)

    {:ok, dev1: dev1, dev2: dev2}
  end

  test "can send a message one way", context do
    {:ok, ref1} = DevBridge.open(context[:dev1], @pipe_filename, [:read])
    {:ok, _ref2} = DevBridge.open(context[:dev2], @pipe_filename, [:write])

    {:ok, 5} = DevBridge.write(context[:dev2], "hello")
    assert_receive {:dev_bridge, ^ref1, :read, "hello"}
  end

  test "empty messages are dropped", context do
    {:ok, ref1} = DevBridge.open(context[:dev1], @pipe_filename, [:read])
    {:ok, _ref2} = DevBridge.open(context[:dev2], @pipe_filename, [:write])

    assert {:ok, 0} = DevBridge.write(context[:dev2], "")
    assert {:ok, 14} = DevBridge.write(context[:dev2], "second message")

    assert_receive {:dev_bridge, ^ref1, :read, "second message"}
    refute_receive _anything_else
  end

  test "reopening provides a new ref", context do
    {:ok, ref1} = DevBridge.open(context[:dev1], @pipe_filename, [:read])
    {:ok, _ref2} = DevBridge.open(context[:dev2], @pipe_filename, [:write])

    assert {:ok, 5} = DevBridge.write(context[:dev2], "first")
    assert_receive {:dev_bridge, ^ref1, :read, "first"}

    {:ok, ref1a} = DevBridge.open(context[:dev1], @pipe_filename, [:read])
    Process.sleep(100)
    assert {:ok, 6} = DevBridge.write(context[:dev2], "second")
    assert_receive {:dev_bridge, ^ref1a, :read, "second"}

    refute_receive _anything_else
  end

  test "opening a missing file sends an error", context do
    {:ok, ref1} = DevBridge.open(context[:dev1], "/dev/bad_device", [:read])

    assert_receive {:dev_bridge, ^ref1, :error, :enoent}
    assert_receive {:dev_bridge, ^ref1, :closed}
    refute_receive _anything_else
  end

  test "writing to a read-only file sends an error", context do
    {:ok, _ref1} = DevBridge.open(context[:dev1], @pipe_filename, [:read])
    {:ok, _ref2} = DevBridge.open(context[:dev2], @pipe_filename, [:write])

    assert {:error, _} = DevBridge.write(context[:dev1], "should fail")
    refute_receive _anything_else
  end
end
