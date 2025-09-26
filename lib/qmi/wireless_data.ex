# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.WirelessData do
  @moduledoc """
  Provides command related to wireless messaging
  """

  alias QMI.Codec

  @doc """
  Start the network interface

  This will return once a packet data session is established and the interface
  can perform IP address configuration. That means once this returns you can
  configure the interface via DHCP.
  """
  @spec start_network_interface(QMI.name(), [
          Codec.WirelessData.start_network_interface_opt()
        ]) :: {:ok, Codec.WirelessData.start_network_report()} | {:error, atom()}
  def start_network_interface(qmi, opts \\ []) do
    Codec.WirelessData.start_network_interface(opts)
    |> QMI.call(qmi)
  end

  @doc """
  Set the event report options for the wireless data event indication
  """
  @spec set_event_report(QMI.name(), [Codec.WirelessData.event_report_opt()]) ::
          :ok | {:error, atom()}
  def set_event_report(qmi, opts \\ []) do
    Codec.WirelessData.set_event_report(opts)
    |> QMI.call(qmi)
  end

  @doc """
  Modify a profile's settings to be used when starting an interface connection
  """
  @spec modify_profile_settings(QMI.name(), profile_index :: integer(), [
          Codec.WirelessData.profile_setting()
        ]) :: {:ok, map()} | {:error, atom()}
  def modify_profile_settings(qmi, profile_index, settings) do
    Codec.WirelessData.modify_profile_settings(profile_index, settings)
    |> QMI.call(qmi)
  end

  @doc """
  Get current WDS settings for the given IP family (4 or 6).
  Returns a map that may include `:ipv4_mtu` and/or `:ipv6_mtu`.

  Options are passed to the codec builder and may include:
  * `:extended_mask` - add Extended Requested Settings (0x11) mask
  * `:packet_data_handle` - include PDH (0x01) for the active session
  """
  @spec get_current_settings(QMI.name(), Codec.WirelessData.ip_family(), [
          Codec.WirelessData.get_current_settings_opt()
        ]) :: {:ok, Codec.WirelessData.current_settings()} | {:error, atom()}
  def get_current_settings(qmi, ip_family \\ 4, opts \\ []) do
    Codec.WirelessData.get_current_settings(ip_family, opts)
    |> QMI.call(qmi)
  end
end
