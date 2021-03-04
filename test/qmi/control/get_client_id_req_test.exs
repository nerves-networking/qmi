defmodule QMI.Control.GetClientIdReqTest do
  use ExUnit.Case, async: true

  alias QMI.Request
  alias QMI.Control.GetClientIdReq

  test "encodes correctly" do
    request = %GetClientIdReq{service_type: 0x01}
    expected_binary = <<0x22, 0x00, 0x04, 0x00, 0x01, 0x01, 0x00, 0x01>>

    assert Request.encode(request) == expected_binary
  end
end
