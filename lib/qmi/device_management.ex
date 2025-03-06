# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Jon Carstens
# SPDX-FileCopyrightText: 2021 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
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

  @doc """
  Get the operating mode
  """
  @spec get_operating_mode(QMI.name()) ::
          {:ok, Codec.DeviceManagement.operating_mode_response()} | {:error, any}
  def get_operating_mode(qmi) do
    Codec.DeviceManagement.get_operating_mode()
    |> QMI.call(qmi)
  end

  @doc """
  Set the operating mode
  """
  @spec set_operating_mode(QMI.name(), Codec.DeviceManagement.operating_mode()) ::
          :ok | {:error, any}
  def set_operating_mode(qmi, mode) do
    Codec.DeviceManagement.set_operating_mode(mode)
    |> QMI.call(qmi)
  end
end
