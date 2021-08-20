defmodule QMI.Codec.DeviceManagementTest do
  use ExUnit.Case, async: true

  alias QMI.Codec.DeviceManagement

  test "get_device_rev_id/0" do
    request = DeviceManagement.get_device_rev_id()

    assert IO.iodata_to_binary(request.payload) == <<35, 0, 0, 0>>
    assert request.service_id == 0x02

    assert request.decode.(
             <<0x23, 0x0, 0x2E, 0x0, 0x2, 0x4, 0x0, 0x0, 0x0, 0x0, 0x0, 0x1, 0x24, 0x0, 0x32,
               0x35, 0x2E, 0x32, 0x30, 0x2E, 0x32, 0x36, 0x36, 0x20, 0x20, 0x31, 0x20, 0x20, 0x5B,
               0x4A, 0x75, 0x6E, 0x20, 0x32, 0x31, 0x20, 0x32, 0x30, 0x31, 0x39, 0x20, 0x31, 0x33,
               0x3A, 0x30, 0x30, 0x3A, 0x30, 0x30, 0x5D>>
           ) == {:ok, "25.20.266  1  [Jun 21 2019 13:00:00]"}
  end

  test "get_device_mfr/0" do
    request = DeviceManagement.get_device_mfr()

    assert IO.iodata_to_binary(request.payload) == <<33, 0, 0, 0>>
    assert request.service_id == 0x02

    response_bin =
      <<33, 0, 31, 0, 2, 4, 0, 0, 0, 0, 0, 1, 21, 0, 81, 85, 65, 76, 67, 79, 77, 77, 32, 73, 78,
        67, 79, 82, 80, 79, 82, 65, 84, 69, 68>>

    assert request.decode.(response_bin) == {:ok, "QUALCOMM INCORPORATED"}
  end
end
