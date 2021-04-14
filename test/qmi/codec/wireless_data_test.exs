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
             %{packet_data_handle: 0x01}
  end
end
