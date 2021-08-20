defmodule QMI.Codec.DeviceManagement do
  @moduledoc """
  Codec for making device management requests
  """

  @get_device_mfr 0x0021
  @get_device_model_id 0x0022
  @get_device_rev_id 0x0023
  @get_device_hardware_rev 0x002C

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
end
