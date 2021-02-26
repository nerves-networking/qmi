defmodule QMI.Service.DeviceManagement do
  use QMI.Service, id: 0x02

  @get_operating_state_mode 0x002D

  @doc """
  Get the operating state mode

  The operating state mode should be `:online` before trying to make a wireless
  data network connection.
  """
  def get_operating_state_mode(device, control_point) do
    # Had to pad 3 bytes
    # output from `strace -x -o /data/qmicli-trace qmicli -d /dev/cdc-wdm0 --dms-get-operating-mode`
    # write(5, "\x01\x0c\x00\x00\x02\x01\x00\x01\x00\x2d\x00\x00\x00", 13) = 13
    # `\x2d` is the start of our request, and it shows that
    bin = <<@get_operating_state_mode::16-little, 0x00, 0x00, 0x00>>

    QMI.Driver.request(device, bin, control_point)
  end

  @impl QMI.Service
  def decode_response_tlvs(%{code: code} = response) when code not in [0, :success] do
    response
  end

  def decode_response_tlvs(%{id: @get_operating_state_mode} = response) do
    mode = decode_mode_tlvs(response.tlvs)

    %{response | tlvs: [mode: mode]}
  end

  defp decode_mode_tlvs(<<0x01, 0x01, mode, _rest::binary>>) do
    mode_from_byte(mode)
  end

  defp mode_from_byte(0x00), do: :online
  defp mode_from_byte(0x01), do: :low_power
  defp mode_from_byte(0x02), do: :factory_test
  defp mode_from_byte(0x03), do: :offline
  defp mode_from_byte(0x04), do: :resetting
  defp mode_from_byte(0x05), do: :shutting_down
  defp mode_from_byte(0x06), do: :persistent_low_power
  defp mode_from_byte(0x07), do: :mode_only_low_power
  defp mode_from_byte(0x08), do: :net_test_gw
end
