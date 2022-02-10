defmodule QMI.Codec.DeviceManagement do
  @moduledoc """
  Codec for making device management requests
  """

  @get_device_mfr 0x0021
  @get_device_model_id 0x0022
  @get_device_rev_id 0x0023
  @get_device_serial_numbers 0x0025
  @get_device_hardware_rev 0x002C
  @get_operating_mode 0x002D
  @set_operating_mode 0x002E

  @typedoc """
  The serial numbers assigned to the device

    * `esn` - for 3GPP2 devices
    * `imei` - for 3GPP devices
    * `meid` - for 3GPP and 3GPP2 devices
    * `imeisv_svn` - for 3GPP devices
  """
  @type serial_numbers() :: %{
          esn: binary() | nil,
          imei: binary() | nil,
          meid: binary() | nil,
          imeisv_svn: binary() | nil
        }

  @doc """
  Get the device hardware revision
  """
  @spec get_device_hardware_rev() :: QMI.request()
  def get_device_hardware_rev() do
    %{
      service_id: 0x02,
      payload: [<<@get_device_hardware_rev::16-little, 0, 0>>],
      decode: &parse_get_device_hardware_rev/1
    }
  end

  @doc """
  Get the device manufacturer
  """
  @spec get_device_mfr() :: QMI.request()
  def get_device_mfr() do
    %{
      service_id: 0x02,
      payload: [<<@get_device_mfr::16-little, 0, 0>>],
      decode: &parse_get_device_mfr/1
    }
  end

  @doc """
  Get the device model
  """
  @spec get_device_model_id() :: QMI.request()
  def get_device_model_id() do
    %{
      service_id: 0x02,
      payload: [<<@get_device_model_id::16-little, 0, 0>>],
      decode: &parse_get_device_model_id/1
    }
  end

  @doc """
  Get the firmware revision id
  """
  @spec get_device_rev_id() :: QMI.request()
  def get_device_rev_id() do
    %{
      service_id: 0x02,
      payload: [<<0x23::16-little, 0x00, 0x00>>],
      decode: &parse_get_device_rev_id/1
    }
  end

  defp parse_get_device_hardware_rev(
         <<@get_device_hardware_rev::16-little, _size::16-little, _result_tlv::7*8, 1,
           len::16-little, hardware_rev::size(len)-binary>>
       ) do
    {:ok, hardware_rev}
  end

  defp parse_get_device_mfr(
         <<@get_device_mfr::16-little, _size::16-little, _result_tlv::7*8, 1, len::16-little,
           mfr::size(len)-binary>>
       ) do
    {:ok, mfr}
  end

  defp parse_get_device_model_id(
         <<@get_device_model_id::16-little, _size::16-little, _result_tlv::7*8, 1, len::16-little,
           model::size(len)-binary>>
       ) do
    {:ok, model}
  end

  defp parse_get_device_rev_id(<<@get_device_rev_id::16-little, _size::16-little, tlvs::binary>>) do
    parse_firmware_rev_id(tlvs)
  end

  defp parse_firmware_rev_id(<<>>) do
    # This is an unexpected response becuase the specification says at least
    # the firmware revision id this is a manditory TLV.
    {:error, :unexpected_response}
  end

  defp parse_firmware_rev_id(<<0x01, size::16-little, rev_id::size(size)-binary, _rest::binary>>) do
    {:ok, rev_id}
  end

  defp parse_firmware_rev_id(<<_type, size::16-little, _values::size(size)-binary, rest::binary>>) do
    parse_firmware_rev_id(rest)
  end

  @doc """
  Request for the serial numbers of the device
  """
  @spec get_device_serial_numbers() :: QMI.request()
  def get_device_serial_numbers() do
    %{
      service_id: 0x02,
      payload: [<<@get_device_serial_numbers::16-little>>, 0x00, 0x00],
      decode: &parse_device_serial_numbers/1
    }
  end

  defp parse_device_serial_numbers(
         <<@get_device_serial_numbers::16-little, _size::16-little, tlvs::binary>>
       ) do
    serial_numbers = %{
      esn: nil,
      imei: nil,
      meid: nil,
      imeisv_svn: nil
    }

    parse_device_serial_numbers(serial_numbers, tlvs)
  end

  defp parse_device_serial_numbers(serial_numbers, <<>>), do: {:ok, serial_numbers}

  defp parse_device_serial_numbers(
         serial_numbers,
         <<0x10, length::16-little, esn::binary-size(length), rest::binary>>
       ) do
    serial_numbers
    |> Map.put(:esn, esn)
    |> parse_device_serial_numbers(rest)
  end

  defp parse_device_serial_numbers(
         serial_numbers,
         <<0x11, length::16-little, imei::binary-size(length), rest::binary>>
       ) do
    serial_numbers
    |> Map.put(:imei, imei)
    |> parse_device_serial_numbers(rest)
  end

  defp parse_device_serial_numbers(
         serial_numbers,
         <<0x12, length::16-little, meid::binary-size(length), rest::binary>>
       ) do
    serial_numbers
    |> Map.put(:meid, meid)
    |> parse_device_serial_numbers(rest)
  end

  defp parse_device_serial_numbers(
         serial_numbers,
         <<0x13, length::16-little, imeisv_svn::binary-size(length), rest::binary>>
       ) do
    serial_numbers
    |> Map.put(:imeisv_svn, imeisv_svn)
    |> parse_device_serial_numbers(rest)
  end

  defp parse_device_serial_numbers(
         serial_numbers,
         <<_type, length::16-little, _values::binary-size(length), rest::binary>>
       ) do
    parse_device_serial_numbers(serial_numbers, rest)
  end

  @operating_modes %{
    0x00 => :online,
    0x01 => :low_power,
    0x02 => :factory_test,
    0x03 => :offline,
    0x04 => :resetting,
    0x05 => :shutting_down,
    0x06 => :persistent_low_power,
    0x07 => :mode_only_low_power,
    0x08 => :network_test_gw
  }

  @type operating_mode ::
          :online
          | :low_power
          | :factory_test
          | :offline
          | :resetting
          | :shutting_down
          | :persistent_low_power
          | :mode_only_low_power
          | :network_test_gw
  @type offline_reason ::
          :host_image_misconfiguration
          | :pri_image_misconfiguration
          | :pri_version_incompatible
          | :device_memory_full
  @type operating_mode_response :: %{
          required(:operating_mode) => operating_mode(),
          optional(:offline_reason) => offline_reason(),
          optional(:hardware_controlled_mode?) => boolean()
        }

  @doc """
  Get the operating mode of a device
  """
  @spec get_operating_mode() :: QMI.request()
  def get_operating_mode() do
    %{
      service_id: 0x02,
      payload: <<@get_operating_mode::16-little, 0, 0>>,
      decode: &parse_operating_mode(%{}, &1)
    }
  end

  defp parse_operating_mode(
         result,
         <<@get_operating_mode::16-little, _size::16-little, _result_tlv::7*8, 1, 1::16-little,
           mode_num, tlvs::binary>>
       ) do
    result
    |> Map.put(:operating_mode, @operating_modes[mode_num])
    |> parse_operating_mode(tlvs)
  end

  defp parse_operating_mode(result, <<0x10, 2::16-little, offline_num::16-little, rest::binary>>) do
    offline_reason =
      case offline_num do
        0x0001 -> :host_image_misconfiguration
        0x0002 -> :pri_image_misconfiguration
        0x0004 -> :pri_version_incompatible
        0x0008 -> :device_memory_full
      end

    Map.put(result, :offline_reason, offline_reason)
    |> parse_operating_mode(rest)
  end

  defp parse_operating_mode(result, <<0x11, 1::16-little, hw_ctl_num, rest::binary>>) do
    Map.put(result, :hardware_controlled_mode?, hw_ctl_num == 1)
    |> parse_operating_mode(rest)
  end

  defp parse_operating_mode(result, <<>>), do: {:ok, result}

  @doc """
  Set operating mode of the device
  """
  @spec set_operating_mode(operating_mode()) :: QMI.request()
  def set_operating_mode(mode) do
    [mode_num] = for {i, ^mode} <- @operating_modes, do: i

    %{
      service_id: 0x02,
      payload: <<@set_operating_mode::16-little, 4::16-little, 1, 1::16-little, mode_num>>,
      decode: fn _ -> :ok end
    }
  end
end
