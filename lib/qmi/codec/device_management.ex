defmodule QMI.Codec.DeviceManagement do
  @moduledoc """
  Codec for making device management requests
  """

  @get_device_rev_id 0x0023

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
