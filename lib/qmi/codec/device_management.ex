defmodule QMI.Codec.DeviceManagement do
  @moduledoc """
  Codec for making device management requests
  """

  @get_device_mfr 0x0021
  @get_device_model_id 0x0022
  @get_device_rev_id 0x0023
  @get_device_serial_numbers 0x0025
  @get_device_hardware_rev 0x002C

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
end
