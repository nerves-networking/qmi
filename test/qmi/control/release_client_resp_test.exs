defmodule QMI.Control.ReleaseClientIdRespTest do
  use ExUnit.Case, async: true

  alias QMI.Response
  alias QMI.Control.ReleaseClientIdResp

  test "parses TLVs correctly" do
    binary = <<0x01, 0x02, 0x00, 0x01, 0x02>>

    expected_response = %ReleaseClientIdResp{
      service_type: 0x01,
      client_id: 0x02
    }

    assert Response.parse_tlvs(%ReleaseClientIdResp{}, binary) == expected_response
  end
end
