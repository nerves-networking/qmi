defmodule QMI.Codec.NetworkAccessTest do
  use ExUnit.Case

  alias QMI.Codec.NetworkAccess

  doctest NetworkAccess

  test "get_signal_strength/0" do
    request = NetworkAccess.get_signal_strength()

    assert IO.iodata_to_binary(request.payload) == <<32, 0, 5, 0, 16, 2, 0, 239, 0>>
    assert request.service_id == 0x03

    assert request.decode.(<<0x20, 0, 7::little-16, 0x11, 2::little-16, 1::little-16, 10, 0x08>>) ==
             {:ok, %{rssi_reports: [%{radio: :lte, rssi: -10}]}}
  end

  describe "get_home_network/0" do
    test "when no service provider information" do
      request = NetworkAccess.get_home_network()

      assert IO.iodata_to_binary(request.payload) == <<37, 0, 0, 0>>
      assert request.service_id == 0x03

      assert request.decode.(
               <<0x25::little-16, 0x08::little-16, 0x01, 0x05::little-16, 0xDD::little-16,
                 0xEF::little-16, 0x00>>
             ) ==
               {:ok, %{mcc: 221, mnc: 239, provider: ""}}
    end

    test "when a service provider is given" do
      request = NetworkAccess.get_home_network()

      assert request.decode.(
               <<0x25::little-16, 0x0D::little-16, 0x01, 0x0A::little-16, 0xDD::little-16,
                 0xEF::little-16, 0x05, "hello"::binary>>
             ) ==
               {:ok, %{mcc: 221, mnc: 239, provider: "hello"}}
    end
  end

  test "parses serving system indication" do
    message = %{
      message:
        <<36, 0, 72, 0, 1, 6, 0, 1, 1, 1, 2, 1, 5, 17, 4, 0, 3, 3, 4, 5, 18, 5, 0, 54, 1, 154, 1,
          0, 40, 2, 0, 115, 0, 41, 5, 0, 54, 1, 154, 1, 1, 0x1E, 0x04, 0x00, 251, 28, 166, 1,
          0x1A, 0x01, 0x00, 0xF0, 0x1B, 0x1, 0x0, 0x01, 0x1C, 0x8, 0x0, 0xE5, 0x7, 0x8, 0x1F,
          0x16, 0x26, 0x5, 0xF0, 0x1D, 0x2, 0x0, 0x5D, 0xBF, 0x10, 0x01, 0x00, 0x01>>,
      service_id: 3,
      transaction_id: 165,
      type: :indication
    }

    assert QMI.Codec.Indication.parse(message) ==
             {:ok,
              %{
                indication_id: 0x0024,
                name: :serving_system_indication,
                service_id: 0x03,
                serving_system_cs_attach_state: :attached,
                serving_system_ps_attach_state: :attached,
                serving_system_radio_interfaces: [:umts],
                serving_system_registration_state: :registered,
                serving_system_selected_network: :network_3gpp,
                cell_id: 27_663_611,
                utc_offset: -18_000,
                std_offset: 3600,
                location_area_code: 48_989,
                network_datetime: ~N[2021-08-31 22:38:05],
                roaming: false
              }}
  end

  test "get RF band information" do
    request = NetworkAccess.get_rf_band_info()

    assert IO.iodata_to_binary(request.payload) == <<0x31, 0, 0, 0>>
    assert request.service_id == 0x03

    assert request.decode.(
             <<0x31, 0x0, 0x10, 0x0, 0x2, 0x4, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1, 0x6, 0x0, 0x1, 0x5,
               0x51, 0x0, 0xAF, 0x2>>
           ) ==
             {:ok, [%{band: "WCDMA PCS 1900", channel: 687, interface: :umts}]}
  end

  test "get cell location information" do
    request = NetworkAccess.get_cell_location_info()

    assert IO.iodata_to_binary(request.payload) == <<0x43, 0, 0, 0>>
    assert request.service_id == 0x03

    assert request.decode.(
             <<0x43, 0, 13, 0, 2, 4, 0, 0, 0, 0, 0, 19, 39, 0, 1, 19, 0, 20, 10, 18, 17, 119, 27,
               1, 246, 19, 57, 0, 2, 2, 2, 62, 2, 57, 0, 140, 255, 240, 251, 14, 253, 26, 0, 78,
               0, 114, 255, 224, 251, 200, 252, 24, 0, 20, 14, 0, 1, 2, 208, 7, 0, 8, 3, 0, 82, 3,
               0, 8, 3, 0, 21, 2, 0, 1, 0, 22, 2, 0, 1, 0, 30, 4, 0, 255, 255, 255, 255, 38, 2, 0,
               70, 0, 39, 4, 0, 246, 19, 0, 0, 40, 9, 0, 2, 208, 7, 0, 0, 82, 3, 0, 0>>
           ) ==
             {:ok,
              %{
                lte_info_intrafrequency: %{
                  ue_in_idle: 1,
                  plmn: <<19, 0, 20>>,
                  tac: 4618,
                  global_cell_id: 18_577_169,
                  earfcn: 5110,
                  serving_cell_id: 57,
                  cell_resel_priority: 2,
                  s_non_intra_search: 2,
                  thresh_serving_low: 2,
                  s_intra_search: 62,
                  cells: [
                    %{rssi: -75.4, pci: 57, rsrq: -11.6, rsrp: -104.0, srxlev: 26},
                    %{rssi: -82.4, pci: 78, rsrq: -14.2, rsrp: -105.6, srxlev: 24}
                  ]
                },
                timing_advance: 4_294_967_295,
                doppler_measurement: 70,
                lte_intra_earfcn: 5110,
                lte_inter_earfcn: [2000, 850]
              }}
  end

  test "parse operator name indication" do
    indication =
      <<58, 0, 25, 0, 20, 22, 0, 1, 0, 0, 0, 8, 0, 65, 0, 84, 0, 38, 0, 84, 8, 0, 65, 0, 84, 0,
        38, 0, 84>>

    message = %{message: indication, service_id: 3}

    assert QMI.Codec.Indication.parse(message) ==
             {:ok, %{name: :operator_name_indication, long_name: "AT&T", short_name: "AT&T"}}
  end

  test "get system selection preference" do
    request = NetworkAccess.get_system_selection_preference()

    assert IO.iodata_to_binary(request.payload) == <<0x34, 0x00, 0x00, 0x00>>
    assert request.service_id == 0x03

    assert request.decode.(
             <<0x34, 0x0, 0x63, 0x0, 0x2, 0x4, 0x0, 0x0, 0x0, 0x0, 0x0, 0x10, 0x1, 0x0, 0x0, 0x11,
               0x2, 0x0, 0x18, 0x0, 0x12, 0x8, 0x0, 0x0, 0x0, 0x80, 0x6, 0x0, 0x0, 0x0, 0x0, 0x14,
               0x2, 0x0, 0xFF, 0x0, 0x15, 0x8, 0x0, 0x1A, 0x38, 0x0, 0x0, 0x0, 0x0, 0x8, 0x8,
               0x16, 0x1, 0x0, 0x0, 0x18, 0x4, 0x0, 0x2, 0x0, 0x0, 0x0, 0x19, 0x4, 0x0, 0x2, 0x0,
               0x0, 0x0, 0x1A, 0x8, 0x0, 0x3F, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1C, 0x3, 0x0,
               0x2, 0x8, 0x5, 0x1D, 0x4, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1F, 0x4, 0x0, 0x1, 0x0, 0x0,
               0x0, 0x20, 0x4, 0x0, 0x3, 0x0, 0x0, 0x0>>
           ) ==
             {:ok,
              %{
                acquisition_order: [:lte, :umts],
                emergency_mode: :off,
                mode_preference: [:lte, :umts],
                network_selection_preference: :automatic,
                registration_restriction: :unrestricted,
                roaming_preference: :any,
                usage_setting: :voice_centric,
                void_domain_preference: :ps_preferred
              }}
  end

  describe "set system selection preference" do
    test "when mode preference is not given" do
      request = NetworkAccess.set_system_selection_preference()

      assert IO.iodata_to_binary(request.payload) == <<0x33, 0x0, 0x4, 0x0, 0x17, 0x1, 0x0, 0x1>>
      assert request.service_id == 0x03
    end

    test "when mode preference is just set to :lte" do
      request = NetworkAccess.set_system_selection_preference(mode_preference: [:lte])

      assert IO.iodata_to_binary(request.payload) ==
               <<0x33, 0x0, 0x9, 0x0, 0x17, 0x1, 0x0, 0x1, 0x11, 0x2, 0x0, 0x10, 0x0>>

      assert request.service_id == 0x03
    end

    test "when mode preference is just set to :umts" do
      request = NetworkAccess.set_system_selection_preference(mode_preference: [:umts])

      assert IO.iodata_to_binary(request.payload) ==
               <<0x33, 0x0, 0x9, 0x0, 0x17, 0x1, 0x0, 0x1, 0x11, 0x2, 0x0, 0x8, 0x0>>

      assert request.service_id == 0x03
    end

    test "when mode preference is contains lte and umts" do
      request = NetworkAccess.set_system_selection_preference(mode_preference: [:lte, :umts])

      assert IO.iodata_to_binary(request.payload) ==
               <<0x33, 0x0, 0x9, 0x0, 0x17, 0x1, 0x0, 0x1, 0x11, 0x2, 0x0, 0x18, 0x0>>

      assert request.service_id == 0x03
    end
  end
end
