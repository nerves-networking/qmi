defmodule QMI.Control.GetClientIdRespTest do
  use ExUnit.Case, async: true

  alias QMI.Response
  alias QMI.Control.GetClientIdResp

  test "parses TLVs correctly" do
    binary = <<0x01, 0x02, 0x00, 0x01, 0x01>>

    expected_resp = %GetClientIdResp{
      service_type: 0x01,
      client_id: 0x01
    }

    assert Response.parse_tlvs(%GetClientIdResp{}, binary) == expected_resp
  end
end
