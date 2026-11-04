# SPDX-FileCopyrightText: 2021 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
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

  test "start_network_interface/1 with a 3GPP profile specified" do
    request = WirelessData.start_network_interface(apn: "apn", profile_3gpp_index: 1)
    bin = :erlang.iolist_to_binary(request.payload)

    assert <<_header::4-unit(8), 0x14, 0x03::little-16, "apn"::binary, 0x31, 0x01::little-16,
             0x01>> = bin
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

  describe "set_event_report/1" do
    test "with no options" do
      request = WirelessData.set_event_report()

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0xFF, 0x03, 0x00, 0x00>>] = request.payload
    end

    test "with stats interval option" do
      request = WirelessData.set_event_report(statistics_interval: 30)

      assert [_header, <<0x11, 0x05::little-16, 30, 0xFF, 0x03, 0x00, 0x00>>] = request.payload
    end

    test "with no stats" do
      request = WirelessData.set_event_report(statistics: :none)

      assert [_header, <<>>] = request.payload
    end

    test "with tx_packets option" do
      request = WirelessData.set_event_report(statistics: [:tx_packets])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x01, 0x00, 0x00, 0x00>>] = request.payload
    end

    test "with rx_packets option" do
      request = WirelessData.set_event_report(statistics: [:rx_packets])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x02, 0x00, 0x00, 0x00>>] = request.payload
    end

    test "with tx_errors option" do
      request = WirelessData.set_event_report(statistics: [:tx_errors])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x04, 0x00, 0x00, 0x00>>] = request.payload
    end

    test "with rx_errors option" do
      request = WirelessData.set_event_report(statistics: [:rx_errors])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x08, 0x00, 0x00, 0x00>>] = request.payload
    end

    test "with tx_overflows" do
      request = WirelessData.set_event_report(statistics: [:tx_overflows])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x10, 0x00, 0x00, 0x00>>] = request.payload
    end

    test "with rx_overflows" do
      request = WirelessData.set_event_report(statistics: [:rx_overflows])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x20, 0x00, 0x00, 0x00>>] = request.payload
    end

    test "with tx_bytes" do
      request = WirelessData.set_event_report(statistics: [:tx_bytes])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x40, 0x00, 0x00, 0x00>>] = request.payload
    end

    test "with rx_bytes" do
      request = WirelessData.set_event_report(statistics: [:rx_bytes])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x80, 0x00, 0x00, 0x00>>] = request.payload
    end

    test "with tx_drops" do
      request = WirelessData.set_event_report(statistics: [:tx_drops])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x00, 0x01, 0x00, 0x00>>] = request.payload
    end

    test "with rx_drops" do
      request = WirelessData.set_event_report(statistics: [:rx_drops])

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0x00, 0x02, 0x00, 0x00>>] = request.payload
    end

    test "only a few stats requested" do
      request =
        WirelessData.set_event_report(
          statistics: [:tx_packets, :rx_packets, :tx_bytes, :rx_bytes, :rx_drops]
        )

      assert [_header, <<0x11, 0x05::little-16, 0x3C, 0xC3, 0x02, 0x00, 0x00>>] = request.payload
    end
  end

  test "parsing event report indication" do
    binary =
      <<0x1, 0x0, 0x4E, 0x0, 0x10, 0x4, 0x0, 0x1C, 0x0, 0x0, 0x0, 0x11, 0x4, 0x0, 0x10, 0x0, 0x0,
        0x0, 0x12, 0x4, 0x0, 0xFF, 0xFF, 0xFF, 0xFF, 0x13, 0x4, 0x0, 0xFF, 0xFF, 0xFF, 0xFF, 0x14,
        0x4, 0x0, 0xFF, 0xFF, 0xFF, 0xFF, 0x15, 0x4, 0x0, 0xFF, 0xFF, 0xFF, 0xFF, 0x19, 0x8, 0x0,
        0xF0, 0x5, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1A, 0x8, 0x0, 0x80, 0x3, 0x0, 0x0, 0x0, 0x0,
        0x0, 0x0, 0x25, 0x4, 0x0, 0x0, 0x0, 0x0, 0x0, 0x26, 0x4, 0x0, 0x0, 0x0, 0x0, 0x0>>

    assert {:ok,
            %{
              name: :event_report_indication,
              rx_bytes: 896,
              rx_errors: 0,
              rx_overflows: 0,
              rx_packets: 16,
              tx_bytes: 1520,
              tx_errors: 0,
              tx_overflows: 0,
              tx_packets: 28,
              tx_drops: 0,
              rx_drops: 0
            }} ==
             WirelessData.parse_indication(binary)
  end

  describe "modifying profile" do
    test "roaming is allowed" do
      request = WirelessData.modify_profile_settings(0x01, roaming_disallowed: false)
      bin = :erlang.iolist_to_binary(request.payload)

      assert <<_header::4-unit(8), 0x01, 0x02::little-16, 0x00, 01, 0x3E, 0x01::little-16, 0x00>> =
               bin
    end

    test "roaming is not allowed" do
      request = WirelessData.modify_profile_settings(0x01, roaming_disallowed: true)
      bin = :erlang.iolist_to_binary(request.payload)

      assert <<_header::4-unit(8), 0x01, 0x02::little-16, 0x00, 01, 0x3E, 0x01::little-16, 0x01>> =
               bin
    end

    test "can handle 3gpp2 profile type" do
      request =
        WirelessData.modify_profile_settings(0x01,
          roaming_disallowed: false,
          profile_type: :profile_type_3gpp2
        )

      bin = :erlang.iolist_to_binary(request.payload)

      assert <<_header::4-unit(8), 0x01, 0x02::little-16, 0x01, 01, 0x3E, 0x01::little-16, 0x00>> =
               bin
    end

    test "can handle EPC profile type" do
      request =
        WirelessData.modify_profile_settings(0x01,
          roaming_disallowed: false,
          profile_type: :profile_type_epc
        )

      bin = :erlang.iolist_to_binary(request.payload)

      assert <<_header::4-unit(8), 0x01, 0x02::little-16, 0x02, 01, 0x3E, 0x01::little-16, 0x00>> =
               bin
    end
  end

  describe "get_current_settings parsing" do
    test "parses IPv4 and IPv6 MTU TLVs" do
      # IPv4 MTU (0x25) 2-byte value = 1500 (0x05DC)
      # IPv6 MTU (0x24) 4-byte value = 1500 (0x000005DC)
      tlvs =
        <<0x25, 0x02::little-16, 0x05DC::little-16, 0x24, 0x04::little-16, 0x000005DC::little-32>>

      size = byte_size(tlvs)
      binary = <<0x002D::little-16, size::little-16, tlvs::binary>>

      assert {:ok, %{ipv4_mtu: 1500, ipv6_mtu: 1500}} =
               WirelessData.parse_get_current_settings_resp(binary)
    end

    test "parses generic MTU TLV (0x29) and populates both families when absent" do
      # Generic MTU (0x29) 4-byte value = 1460 (0x000005B4)
      tlvs = <<0x29, 0x04::little-16, 0x000005B4::little-32>>

      size = byte_size(tlvs)
      binary = <<0x002D::little-16, size::little-16, tlvs::binary>>

      assert {:ok, %{ipv4_mtu: 1460, ipv6_mtu: 1460}} =
               WirelessData.parse_get_current_settings_resp(binary)
    end
  end

  describe "get_current_settings real-world and error cases" do
    test "parses real-world TLVs from modem log (generic MTU 1400) and ignores unknowns" do
      # TLVs captured from modem debug for GetCurrentSettings
      hex =
        "020400000000001101000015040008080808160400040408081d0100001e04006368880a1f020000012004006468880a210400f8ffffff220100002301000024010000290400780500002a0100002b0100042c0100002d02008088"

      tlvs = Base.decode16!(hex, case: :mixed)
      size = byte_size(tlvs)
      binary = <<0x002D::little-16, size::little-16, tlvs::binary>>

      assert {:ok, %{ipv4_mtu: 1400, ipv6_mtu: 1400}} =
               WirelessData.parse_get_current_settings_resp(binary)
    end

    test "returns empty map when no MTU-related TLVs are present" do
      # Include a couple of unrelated TLVs only
      tlvs = <<0x02, 0x04::little-16, 0x00::little-32, 0x22, 0x01::little-16, 0x00>>
      size = byte_size(tlvs)
      binary = <<0x002D::little-16, size::little-16, tlvs::binary>>

      assert {:ok, %{}} = WirelessData.parse_get_current_settings_resp(binary)
    end

    test "returns error for unexpected response header/body" do
      # Wrong message id and zero size should not match the parser
      assert {:error, :unexpected_response} =
               WirelessData.parse_get_current_settings_resp(
                 <<0xFFFF::little-16, 0x0000::little-16>>
               )
    end
  end

  describe "profile settings TLVs" do
    test "modify encodes name, APN, credentials and auth with the spec TLV types" do
      request =
        WirelessData.modify_profile_settings(3,
          profile_name: "data",
          apn: "fixedip.m2m",
          pdp_type: :ipv4,
          username: "u",
          password: "p",
          auth_method: :chap
        )

      <<0x28::little-16, size::little-16, tlvs::binary>> =
        :erlang.iolist_to_binary(request.payload)

      assert size == byte_size(tlvs)

      assert tlvs ==
               <<0x01, 2::little-16, 0x00, 3, 0x10, 4::little-16, "data", 0x14, 11::little-16,
                 "fixedip.m2m", 0x11, 1::little-16, 0x00, 0x1B, 1::little-16, "u", 0x1C,
                 1::little-16, "p", 0x1D, 1::little-16, 0x02>>
    end

    test "get profile settings decodes the spec TLV types" do
      tlvs =
        <<0x02, 4::little-16, 0::32, 0x10, 14::little-16, "qdp_profile_ia", 0x11, 1::little-16,
          0x00, 0x14, 11::little-16, "fixedip.m2m", 0x1B, 0::little-16, 0x1C, 0::little-16, 0x1D,
          1::little-16, 0x00, 0x3E, 1::little-16, 0x00>>

      request = WirelessData.get_profile_settings(3)

      assert {:ok,
              %{
                profile_name: "qdp_profile_ia",
                apn: "fixedip.m2m",
                pdp_type: :ipv4,
                username: "",
                password: "",
                auth_method: :none,
                roaming_disallowed: false
              }} == request.decode.(<<0x2B::little-16, byte_size(tlvs)::little-16, tlvs::binary>>)
    end
  end

  describe "creating a profile" do
    test "encodes the profile type and settings" do
      request = WirelessData.create_profile(apn: "fixedip.m2m", pdp_type: :ipv4)

      <<0x27::little-16, size::little-16, tlvs::binary>> =
        :erlang.iolist_to_binary(request.payload)

      assert size == byte_size(tlvs)

      assert tlvs ==
               <<0x01, 1::little-16, 0x00, 0x14, 11::little-16, "fixedip.m2m", 0x11, 1::little-16,
                 0x00>>
    end

    test "decodes the new profile index" do
      request = WirelessData.create_profile(apn: "a")
      tlvs = <<0x02, 4::little-16, 0::32, 0x01, 2::little-16, 0x00, 4>>

      assert {:ok, %{index: 4}} ==
               request.decode.(<<0x27::little-16, byte_size(tlvs)::little-16, tlvs::binary>>)
    end
  end

  describe "default profile number" do
    test "asks for the embedded 3GPP default and decodes the index" do
      request = WirelessData.get_default_profile_number()

      assert <<0x49::little-16, 5::little-16, 0x01, 2::little-16, 0x00, 0x00>> ==
               :erlang.iolist_to_binary(request.payload)

      tlvs = <<0x02, 4::little-16, 0::32, 0x01, 1::little-16, 1>>

      assert {:ok, 1} ==
               request.decode.(<<0x49::little-16, byte_size(tlvs)::little-16, tlvs::binary>>)
    end
  end

  describe "LTE attach PDN list" do
    test "decodes the current list" do
      request = WirelessData.get_lte_attach_pdn_list()
      tlvs = <<0x02, 4::little-16, 0::32, 0x10, 5::little-16, 2, 3::little-16, 7::little-16>>

      assert {:ok, [3, 7]} ==
               request.decode.(<<0x94::little-16, byte_size(tlvs)::little-16, tlvs::binary>>)
    end

    test "returns an empty list when the modem reports none" do
      request = WirelessData.get_lte_attach_pdn_list()
      tlvs = <<0x02, 4::little-16, 0::32>>

      assert {:ok, []} ==
               request.decode.(<<0x94::little-16, byte_size(tlvs)::little-16, tlvs::binary>>)
    end
  end

  test "start network interface encodes the IP family" do
    request = WirelessData.start_network_interface(profile_3gpp_index: 3, ip_family: 4)

    assert <<0x20::little-16, 8::little-16, 0x31, 1::little-16, 3, 0x19, 1::little-16, 4>> ==
             :erlang.iolist_to_binary(request.payload)
  end
end
