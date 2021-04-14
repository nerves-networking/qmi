defmodule QMI.Codec.NetworkAccessTest do
  use ExUnit.Case

  alias QMI.Codec.NetworkAccess

  doctest NetworkAccess

  test "get_signal_strength/0" do
    request = NetworkAccess.get_signal_strength()

    assert IO.iodata_to_binary(request.payload) == <<32, 0, 5, 0, 16, 2, 0, 239, 0>>
    assert request.service_id == 0x03

    # TODO - Fix this binary with something realistic
    assert request.decode.(<<0x20, 0, 5::little-16, 0x11, 2::little-16, 1::little-16, 10, 0>>) ==
             %{rssis: [%{radio: :lte, rssi: -10}]}
  end
end
