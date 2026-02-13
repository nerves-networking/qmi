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
  Modify a profile's settings to be used when starting an interface connection.

  Available settings:
  * `:apn` - the Access Point Name (e.g., "simbase")
  * `:username` - username for authentication
  * `:password` - password for authentication
  * `:pdp_type` - :ipv4, :ipv6, :ipv4v6, or :ppp
  * `:auth_method` - :none, :pap, :chap, or :pap_or_chap
  * `:roaming_disallowed` - true/false for roaming restrictions
  * `:profile_type` - :profile_type_3gpp, :profile_type_3gpp2, or :profile_type_epc

  ## Examples

      # Configure a profile for "simbase" APN
      QMI.WirelessData.modify_profile_settings(client, 1, [
        apn: "simbase",
        pdp_type: :ipv4v6,
        auth_method: :none
      ])

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

  Returns comprehensive network configuration including IP addresses, DNS servers,
  gateway, MTU, and domain information assigned by the modem during connection.

  ## Returned Information

  * **IPv4 Configuration**: `:ipv4_address`, `:ipv4_gateway`, `:ipv4_subnet_mask`,
    `:ipv4_primary_dns`, `:ipv4_secondary_dns`, `:ipv4_mtu`
  * **IPv6 Configuration**: `:ipv6_address`, `:ipv6_gateway`, `:ipv6_prefix_length`,
    `:ipv6_primary_dns`, `:ipv6_secondary_dns`, `:ipv6_mtu`
  * **Domain Information**: `:domain_name_list`, `:pcscf_domain_name_list`
  * **PCSCF**: `:pcscf_address_using_pco`

  ## Options

  * `:extended_mask` - add Extended Requested Settings (0x11) mask
  * `:packet_data_handle` - include PDH (0x01) for the active session

  ## Examples

      # Get IPv4 configuration
      {:ok, settings} = QMI.WirelessData.get_current_settings(client, 4)
      # Returns: %{ipv4_address: "192.168.1.100", ipv4_gateway: "192.168.1.1", ...}

      # Get IPv6 configuration
      {:ok, settings} = QMI.WirelessData.get_current_settings(client, 6)
      # Returns: %{ipv6_address: "2001:db8::1", ipv6_gateway: "2001:db8::1", ...}

  """
  @spec get_current_settings(QMI.name(), Codec.WirelessData.ip_family(), [
          Codec.WirelessData.get_current_settings_opt()
        ]) :: {:ok, Codec.WirelessData.current_settings()} | {:error, atom()}
  def get_current_settings(qmi, ip_family \\ 4, opts \\ []) do
    Codec.WirelessData.get_current_settings(ip_family, opts)
    |> QMI.call(qmi)
  end

  @doc """
  Get the list of all configured profiles by iterating through profile indices.

  Starts at index 1 and continues until receiving {:error, :extended_internal},
  which indicates we've reached the end of available profiles.

  """
  @spec get_profile_list(QMI.name(), keyword()) :: {:ok, [map()]} | {:error, term()}
  def get_profile_list(client, opts \\ []) do
    profile_type = Keyword.get(opts, :profile_type, :profile_type_3gpp)
    max_profiles = Keyword.get(opts, :max_profiles, 255)

    collect_profiles(client, profile_type, 1, max_profiles, [])
  end

  defp collect_profiles(_client, _type, index, max_index, acc) when index > max_index do
    {:ok, Enum.reverse(acc)}
  end

  defp collect_profiles(client, profile_type, index, max_index, acc) do
    case get_profile_settings(client, index, profile_type) do
      {:ok, settings} ->
        profile = Map.put(settings, :index, index)
        collect_profiles(client, profile_type, index + 1, max_index, [profile | acc])

      {:error, :extended_internal} ->
        # This is the expected error when we reach the end of profiles
        {:ok, Enum.reverse(acc)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Get the settings for a specific profile by index.

  """
  @spec get_profile_settings(QMI.name(), integer(), atom()) :: {:ok, map()} | {:error, term()}
  def get_profile_settings(qmi, index, profile_type \\ :profile_type_3gpp) do
    QMI.Codec.WirelessData.get_profile_settings(index, profile_type) |> QMI.call(qmi)
  end
end
