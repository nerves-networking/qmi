defmodule QMI.Codec.NetworkAccessTest do
  use ExUnit.Case

  alias QMI.Codec.NetworkAccess

  doctest NetworkAccess

  test "get_signal_strength/0" do
    request = NetworkAccess.get_signal_strength()

    assert IO.iodata_to_binary(request.payload) == <<32, 0, 5, 0, 16, 2, 0, 239, 0>>
    assert request.service_id == 0x03

    assert request.decode.(<<0x20, 0, 7::little-16, 0x11, 2::little-16, 1::little-16, 10, 0x08>>) ==
             {:ok, %{rssis: [%{radio: :lte, rssi: -10}]}}
  end

  test "get_home_network/0" do
    request = NetworkAccess.get_home_network()

    assert IO.iodata_to_binary(request.payload) == <<37, 0, 0, 0>>
    assert request.service_id == 0x03

    assert request.decode.(
             <<0x25::little-16, 0x07::little-16, 0x01, 0x04::little-16, 0xDD::little-16,
               0xEF::little-16>>
           ) ==
             {:ok, %{mcc: 221, mnc: 239}}
  end
end
