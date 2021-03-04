defmodule QMI.DeviceManagement.GetOperatingModeReqTest do
  use ExUnit.Case, async: true

  alias QMI.Request
  alias QMI.DeviceManagement.GetOperatingModeReq

  test "encodes correctly" do
    request = %GetOperatingModeReq{}

    expect_binary = <<0x2D, 0x00, 0x00, 0x00, 0x00>>

    assert Request.encode(request) == expect_binary
  end
end
