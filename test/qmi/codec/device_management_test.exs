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

  test "get_device_model_id/0" do
    request = DeviceManagement.get_device_model_id()

    assert IO.iodata_to_binary(request.payload) == <<34, 0, 0, 0>>
    assert request.service_id == 0x02

    response_bin =
      <<34, 0, 40, 0, 2, 4, 0, 0, 0, 0, 0, 1, 31, 0, 81, 85, 69, 67, 84, 69, 76, 32, 77, 111, 98,
        105, 108, 101, 32, 66, 114, 111, 97, 100, 98, 97, 110, 100, 32, 77, 111, 100, 117, 108,
        101>>

    assert request.decode.(response_bin) == {:ok, "QUECTEL Mobile Broadband Module"}
  end

  test "get_device_hardware_rev/0" do
    request = DeviceManagement.get_device_hardware_rev()

    assert IO.iodata_to_binary(request.payload) == <<44, 0, 0, 0>>
    assert request.service_id == 0x02

    response_bin = <<44, 0, 40, 0, 2, 4, 0, 0, 0, 0, 0, 1, 5, 0, 49, 48, 48, 48, 48>>

    assert request.decode.(response_bin) == {:ok, "10000"}
  end

  describe "get_device_serial_numbers/0" do
    test "ESN serial number" do
      request = DeviceManagement.get_device_serial_numbers()

      response_bin = <<0x0025::16-little, 0x05::16-little, 0x10, 0x02, 0x00, 0x01, 0x02>>

      {:ok, serial_numbers} = request.decode.(response_bin)

      assert serial_numbers.esn == <<0x01, 0x02>>
    end

    test "IMEI serial number" do
      request = DeviceManagement.get_device_serial_numbers()

      response_bin = <<0x0025::16-little, 0x05::16-little, 0x11, 0x02, 0x00, 0x01, 0x02>>

      {:ok, serial_numbers} = request.decode.(response_bin)

      assert serial_numbers.imei == <<0x01, 0x02>>
    end

    test "MEID serial number" do
      request = DeviceManagement.get_device_serial_numbers()

      response_bin = <<0x0025::16-little, 0x05::16-little, 0x12, 0x02, 0x00, 0x01, 0x02>>

      {:ok, serial_numbers} = request.decode.(response_bin)

      assert serial_numbers.meid == <<0x01, 0x02>>
    end

    test "IMEI version" do
      request = DeviceManagement.get_device_serial_numbers()

      response_bin = <<0x0025::16-little, 0x04::16-little, 0x13, 0x01, 0x00, 0x01>>

      {:ok, serial_numbers} = request.decode.(response_bin)

      assert serial_numbers.imeisv_svn == <<0x01>>
    end
  end

  describe "get_operating_mode/0" do
    test "operating mode" do
      %{decode: decode} = DeviceManagement.get_operating_mode()

      base = <<0x002D::16-little, 11::16-little, 2, 4, 0, 0, 0, 0, 0, 1, 1::16-little>>

      assert {:ok, %{operating_mode: :online}} = decode.(base <> <<0x00>>)
      assert {:ok, %{operating_mode: :low_power}} = decode.(base <> <<0x01>>)
      assert {:ok, %{operating_mode: :factory_test}} = decode.(base <> <<0x02>>)
      assert {:ok, %{operating_mode: :offline}} = decode.(base <> <<0x03>>)
      assert {:ok, %{operating_mode: :resetting}} = decode.(base <> <<0x04>>)
      assert {:ok, %{operating_mode: :shutting_down}} = decode.(base <> <<0x05>>)
      assert {:ok, %{operating_mode: :persistent_low_power}} = decode.(base <> <<0x06>>)
      assert {:ok, %{operating_mode: :mode_only_low_power}} = decode.(base <> <<0x07>>)
      assert {:ok, %{operating_mode: :network_test_gw}} = decode.(base <> <<0x08>>)
    end

    test "offline reason" do
      %{decode: decode} = DeviceManagement.get_operating_mode()

      # offline operating mode
      base =
        <<0x002D::16-little, 11::16-little, 2, 4, 0, 0, 0, 0, 0, 1, 1::16-little, 3, 0x10,
          2::16-little>>

      assert {:ok, %{offline_reason: :host_image_misconfiguration}} =
               decode.(base <> <<0x001::16-little>>)

      assert {:ok, %{offline_reason: :pri_image_misconfiguration}} =
               decode.(base <> <<0x02::16-little>>)

      assert {:ok, %{offline_reason: :pri_version_incompatible}} =
               decode.(base <> <<0x04::16-little>>)

      assert {:ok, %{offline_reason: :device_memory_full}} = decode.(base <> <<0x08::16-little>>)
    end

    test "hardware controlled mode" do
      %{decode: decode} = DeviceManagement.get_operating_mode()

      base =
        <<0x002D::16-little, 11::16-little, 2, 4, 0, 0, 0, 0, 0, 1, 1::16-little, 1, 0x11,
          1::16-little>>

      assert {:ok, %{hardware_controlled_mode?: true}} = decode.(base <> <<1>>)
      assert {:ok, %{hardware_controlled_mode?: false}} = decode.(base <> <<0>>)
      assert {:ok, %{hardware_controlled_mode?: false}} = decode.(base <> <<2>>)
    end

    test "multi part message" do
      %{decode: decode} = DeviceManagement.get_operating_mode()

      bin =
        <<0x002D::16-little, 11::16-little, 2, 4, 0, 0, 0, 0, 0, 1, 1::16-little, 3, 0x10,
          2::16-little, 8::16-little, 0x11, 1, 0, 1>>

      {:ok, result} = decode.(bin)
      assert result.operating_mode == :offline
      assert result.offline_reason == :device_memory_full
      assert result.hardware_controlled_mode?
    end
  end
end
