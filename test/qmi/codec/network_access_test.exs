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
             {:ok, [%{band: 81, channel: 687, interface: :umts}]}
  end
end
