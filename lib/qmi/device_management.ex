defmodule QMI.DeviceManagement do
  @moduledoc """
  Device Management service requests
  """

  alias QMI.Codec

  @doc """
  Get the hardware information
  """
  @spec get_hardware_rev(QMI.name()) :: {:ok, map()} | {:error, any()}
  def get_hardware_rev(qmi) do
    Codec.DeviceManagement.get_device_hardware_rev()
    |> QMI.call(qmi)
  end

  @doc """
  Get the firmware information
  """
  @spec get_firmware_rev(QMI.name()) :: {:ok, map()} | {:error, any()}
  def get_firmware_rev(qmi) do
    Codec.DeviceManagement.get_device_rev_id()
    |> QMI.call(qmi)
  end

  @doc """
  Get the device manufacturer information
  """
  @spec get_manufacturer(QMI.name()) :: {:ok, binary()} | {:error, any()}
  def get_manufacturer(qmi) do
    Codec.DeviceManagement.get_device_mfr()
    |> QMI.call(qmi)
  end

  @doc """
  Get the device model information
  """
  @spec get_model(QMI.name()) :: {:ok, binary()} | {:error, any()}
  def get_model(qmi) do
    Codec.DeviceManagement.get_device_model_id()
    |> QMI.call(qmi)
  end

  @doc """
  Get the device serial numbers
  """
  @spec get_serial_numbers(QMI.name()) ::
          {:ok, Codec.DeviceManagement.serial_numbers()} | {:error, any()}
  def get_serial_numbers(qmi) do
    Codec.DeviceManagement.get_device_serial_numbers()
    |> QMI.call(qmi)
  end
end
