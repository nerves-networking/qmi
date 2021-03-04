defmodule QMI.DeviceManagement.GetOperatingModeRespTest do
  use ExUnit.Case, async: true

  alias QMI.Response
  alias QMI.DeviceManagement.GetOperatingModeResp

  describe "Parsing TLVs" do
    test "when mode is online" do
      online_mode = <<0x01, 0x01, 0x00, 0x00>>
      expected_resp = %GetOperatingModeResp{operating_mode: :online}

      assert Response.parse_tlvs(%GetOperatingModeResp{}, online_mode) == expected_resp
    end

    test "when mode is offline with reasons" do
      offline_mode_with_all_reasons = <<0x01, 0x01, 0x00, 0x03, 0x10, 0x02, 0x00, 0x0F, 0x00>>
      response = Response.parse_tlvs(%GetOperatingModeResp{}, offline_mode_with_all_reasons)

      assert response.operating_mode == :offline
      assert Enum.member?(response.offline_reasons, :host_image_misconfiguration)
      assert Enum.member?(response.offline_reasons, :pri_image_misconfiguration)
      assert Enum.member?(response.offline_reasons, :pri_version_incompatible)
      assert Enum.member?(response.offline_reasons, :device_memory_full)
    end

    test "when mode is offline without reasons - reason offline unknown" do
      offline_mode_no_known_reasons = <<0x01, 0x01, 0x00, 0x03>>

      expected_resp = %GetOperatingModeResp{
        operating_mode: :offline,
        offline_reasons: []
      }

      assert Response.parse_tlvs(%GetOperatingModeResp{}, offline_mode_no_known_reasons) ==
               expected_resp
    end
  end
end
