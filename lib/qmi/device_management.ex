defmodule QMI.DeviceManagement do
  @moduledoc """
  Device Management service requests
  """

  alias QMI.Codec

  @doc """
  Get the firmware information
  """
  @spec get_firmware_rev(QMI.t()) :: {:ok, map()} | {:error, any()}
  def get_firmware_rev(qmi) do
    Codec.DeviceManagement.get_device_rev_id()
    |> QMI.call(qmi)
  end
end
