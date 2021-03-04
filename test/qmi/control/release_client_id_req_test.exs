defmodule QMI.Control.ReleaseClientIdReqTest do
  use ExUnit.Case, async: true

  alias QMI.Request
  alias QMI.Control.ReleaseClientIdReq

  test "encodes correctly" do
    request = %ReleaseClientIdReq{service_type: 0x01, client_id: 0x01}

    expected_binary = <<0x23, 0x00, 0x05, 0x00, 0x01, 0x02, 0x00, 0x01, 0x001>>

    assert Request.encode(request) == expected_binary
  end
end
