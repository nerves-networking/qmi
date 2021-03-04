defmodule QMI.DeviceManagement.GetOperatingModeResp do
  @moduledoc """
  The response for requesting the operating mode

  If the operating mode is offline the the `:offline_reasons` field will contain
  the reasons why if the reasons are known.
  """

  @typedoc """
  Different operating modes the modem can be in:

  * `:online` - Indicates the device is ready and can receive requests.
  * `:low_power` - Indicates the device has temporarily disabled RF but can
    requests.
  * `:factory_test` - Special mode for manufacturer use.
  * `:offline` - The device has been disabled. The device must be powered cycled
    before it can handle requests.
  * `:resetting` - The device is in the process power cycling.
  * `:shutting_down` - The device is in the process of shutting down.
  * `:persistent_low_power` - Same as low power, but persists even if the device
    is reset.
  * `:net_test_gw` - The device is conducting a network test for GSM/WCDMA,
    clients cannot set this mode.
  """
  @type operating_mode() ::
          :online
          | :low_power
          | :factory_test
          | :offline
          | :resetting
          | :shutting_down
          | :persistent_low_power
          | :mode_only_low_power
          | :net_test_gw

  @type offline_reason() ::
          :host_image_misconfiguration
          | :pri_image_misconfiguration
          | :pri_version_incompatible
          | :device_memory_full

  @type t() :: %__MODULE__{
          operating_mode: operating_mode(),
          offline_reasons: [offline_reason()]
        }

  defstruct operating_mode: nil, offline_reasons: []

  defimpl QMI.Response do
    def parse_tlvs(response, <<0x01, 0x01::little-16, mode>>) do
      %QMI.DeviceManagement.GetOperatingModeResp{response | operating_mode: mode_from_byte(mode)}
    end

    # if the operating mode is offline (0x03) then the tlvs may provide a
    # reason for it to be offline
    def parse_tlvs(
          response,
          <<0x01, 0x01::little-16, 0x03, 0x10, 0x02::little-16, offline_reason_mask::little-16>>
        ) do
      %QMI.DeviceManagement.GetOperatingModeResp{
        response
        | operating_mode: :offline,
          offline_reasons: get_reasons_from_mask(offline_reason_mask)
      }
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

    defp get_reasons_from_mask(mask) do
      <<_zeros::4, memory::1, version::1, pri_misconfig::1, host_misconfig::1>> = <<mask>>

      possible_reasons = [
        host_image_misconfiguration: host_misconfig,
        pri_image_misconfiguration: pri_misconfig,
        pri_version_incompatible: version,
        device_memory_full: memory
      ]

      Enum.reduce(possible_reasons, [], fn
        {reason, 1}, reasons -> reasons ++ [reason]
        {_, 0}, reasons -> reasons
      end)
    end
  end
end
