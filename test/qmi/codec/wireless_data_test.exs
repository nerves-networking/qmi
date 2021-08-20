defmodule QMI.Codec.WirelessDataTest do
  use ExUnit.Case, async: true

  alias QMI.Codec.WirelessData

  test "start_network_interface/1" do
    request = WirelessData.start_network_interface(apn: "apn")

    assert IO.iodata_to_binary(request.payload) ==
             <<0x0020::little-16, 0x06::little-16, 0x14, 0x03::little-16, "apn"::binary>>

    assert request.service_id == 0x01

    assert request.decode.(
             <<0x0020::little-16, 0x07::little-16, 0x01, 0x04::little-16, 0x01, 0x00, 0x00,
               0x000>>
           ) ==
             {:ok, %{packet_data_handle: 0x01}}
  end

  describe "parsing packet status indication" do
    test "when connected" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x01, 0x02, 0x00, 0x02, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.status == :connected
    end

    test "when disconnected" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x01, 0x02, 0x00, 0x01, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.status == :disconnected
    end

    test "when suspended" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x01, 0x02, 0x00, 0x03, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.status == :suspended
    end

    test "when authenticating" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x01, 0x02, 0x00, 0x04, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.status == :authenticating
    end

    test "when reconfiguring required" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x01, 0x02, 0x00, 0x04, 0x01>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.reconfiguration_required == true
    end

    test "when reconfiguring not required" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x01, 0x02, 0x00, 0x04, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.reconfiguration_required == false
    end

    test "when call end reason type is unspecified" do
      binary = <<0x22, 0x00, 0x07, 0x00, 0x11, 0x04, 0x00, 0x00::16-little, 0x00, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.call_end_reason_type == :unspecified
    end

    test "when call end reason type is mobile ip" do
      binary = <<0x22, 0x00, 0x07, 0x00, 0x11, 0x04, 0x00, 0x01::16-little, 0x00, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.call_end_reason_type == :mobile_ip
    end

    test "when call end reason type is internal" do
      binary = <<0x22, 0x00, 0x07, 0x00, 0x11, 0x04, 0x00, 0x02::16-little, 0x00, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.call_end_reason_type == :internal
    end

    test "when call end reason type is call manager defined" do
      binary = <<0x22, 0x00, 0x07, 0x00, 0x11, 0x04, 0x00, 0x03::16-little, 0x00, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.call_end_reason_type == :call_manager_defined
    end

    test "when call end reason type is 3GPP defined" do
      binary = <<0x22, 0x00, 0x07, 0x00, 0x11, 0x04, 0x00, 0x06::16-little, 0x00, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.call_end_reason_type == :three_gpp_specification_defined
    end

    test "when call end reason type is PPP" do
      binary = <<0x22, 0x00, 0x07, 0x00, 0x11, 0x04, 0x00, 0x07::16-little, 0x00, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.call_end_reason_type == :ppp
    end

    test "when call end reason type is EHRPD" do
      binary = <<0x22, 0x00, 0x07, 0x00, 0x11, 0x04, 0x00, 0x08::16-little, 0x00, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.call_end_reason_type == :ehrpd
    end

    test "when call end reason type is IPv6" do
      binary = <<0x22, 0x00, 0x07, 0x00, 0x11, 0x04, 0x00, 0x09::16-little, 0x00, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.call_end_reason_type == :ipv6
    end

    test "when call end reason type is handoff" do
      binary = <<0x22, 0x00, 0x07, 0x00, 0x11, 0x04, 0x00, 0x0C::16-little, 0x00, 0x00>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.call_end_reason_type == :handoff
    end

    test "when tech name is CDMA" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x13, 0x02, 0x00, 0x8001::16-little>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.tech_name == :cdma
    end

    test "when tech name is UMTS" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x13, 0x02, 0x00, 0x8004::16-little>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.tech_name == :umts
    end

    test "when tech name is WLAN Local brkout" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x13, 0x02, 0x00, 0x8020::16-little>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.tech_name == :wlan_local_brkout
    end

    test "when tech name is iWLAN S2b" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x13, 0x02, 0x00, 0x8021::16-little>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.tech_name == :iwlan_s2b
    end

    test "when tech name is EPC" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x13, 0x02, 0x00, 0x8880::16-little>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.tech_name == :epc
    end

    test "when tech name is EMBMS" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x13, 0x02, 0x00, 0x8882::16-little>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.tech_name == :embms
    end

    test "when tech name is modem link local" do
      binary = <<0x22, 0x00, 0x05, 0x00, 0x13, 0x02, 0x00, 0x8888::16-little>>

      {:ok, indication} = WirelessData.parse_indication(binary)

      assert indication.tech_name == :modem_link_local
    end
  end
end
