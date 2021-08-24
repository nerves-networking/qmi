defmodule QMI.Codec.WirelessData do
  @moduledoc """
  Codec for making wireless data service requests
  """

  @start_network_interface 0x0020
  @packet_service_status_ind 0x0022

  @typedoc """
  Options for whens starting a network interface

  * `:apn` - the name of our APN
  """
  @type start_network_interface_opt() :: {:apn, String.t()}

  @typedoc """
  Report from starting the network interface
  """
  @type start_network_report() :: %{packet_data_handle: non_neg_integer()}

  @typedoc """
  The type of reasons the call ended
  """
  @type call_end_reason_type() ::
          :unspecified
          | :mobile_ip
          | :internal
          | :call_manger_defined
          | :three_gpp_specification_defined
          | :ppp
          | :ehrpd
          | :ipv6
          | :handoff

  @typedoc """
  Name of the technology
  """
  @type tech_name() ::
          :cdma | :umts | :wlan_local_brkout | :iwlan_s2b | :epc | :embms | :modem_link_local

  @typedoc """
  The indication for a change in the current packet data connection status
  """
  @type packet_status_indication() :: %{
          name: :packet_status_indication,
          status: :disconnected | :connected | :suspended | :authenticating,
          reconfiguration_required: boolean(),
          call_end_reason: integer() | nil,
          call_end_reason_type: call_end_reason_type() | nil,
          ip_family: 4 | 6 | nil,
          tech_name: tech_name() | nil,
          bearer_id: integer() | nil,
          xlat_capable: boolean() | nil
        }

  @doc """
  Send command to request the that the network interface starts to receive data
  """
  @spec start_network_interface([start_network_interface_opt()]) :: QMI.request()
  def start_network_interface(opts \\ []) do
    {tlvs, size} = make_tlvs(opts, [], 0)
    payload = [<<@start_network_interface::little-16, size::little-16>>, tlvs]

    %{service_id: 0x01, payload: payload, decode: &parse_start_network_interface_resp/1}
  end

  defp make_tlvs([], tlvs, size) do
    {tlvs, size}
  end

  defp make_tlvs([{:apn, apn} | rest], tlvs, size) do
    apn_size = byte_size(apn)
    new_size = size + 3 + apn_size
    new_tlvs = [tlvs, <<0x14, apn_size::little-16>>, apn]
    make_tlvs(rest, new_tlvs, new_size)
  end

  defp parse_start_network_interface_resp(
         <<@start_network_interface::little-16, size::little-16, tlvs::size(size)-binary>>
       ) do
    {:ok, parse_start_network_interface_tlvs(%{}, tlvs)}
  end

  defp parse_start_network_interface_resp(_other) do
    {:error, :unexpected_response}
  end

  defp parse_start_network_interface_tlvs(parsed, <<>>) do
    parsed
  end

  defp parse_start_network_interface_tlvs(
         parsed,
         <<0x01, 0x04, 0x00, packet_data_handle::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:packet_data_handle, packet_data_handle)
    |> parse_start_network_interface_tlvs(rest)
  end

  defp parse_start_network_interface_tlvs(
         parsed,
         <<_type, length::little-16, _values::size(length)-unit(8)-binary, rest::binary>>
       ) do
    parse_start_network_interface_tlvs(parsed, rest)
  end

  @doc """
  Try to parse an indication from the wireless data service
  """
  @spec parse_indication(binary()) ::
          {:ok, packet_status_indication()} | {:error, :invalid_indication}
  def parse_indication(
        <<@packet_service_status_ind::16-little, size::16-little, tlvs::binary-size(size)>>
      ) do
    result = parse_packet_status_indication(packet_status_indication_init(), tlvs)

    {:ok, result}
  end

  def parse_indication(_other) do
    {:error, :invalid_indication}
  end

  defp packet_status_indication_init() do
    %{
      name: :packet_status_indication,
      status: nil,
      reconfiguration_required: nil,
      call_end_reason: nil,
      call_end_reason_type: nil,
      ip_family: nil,
      tech_name: nil,
      bearer_id: nil,
      xlat_capable: nil
    }
  end

  defp parse_packet_status_indication(indication, <<>>) do
    indication
  end

  defp parse_packet_status_indication(
         indication,
         <<0x01, 0x02, 0x00, connection_status, reconfig_required, rest::binary>>
       ) do
    indication
    |> Map.put(:status, parse_packet_status(connection_status))
    |> Map.put(:reconfiguration_required, reconfig_required == 1)
    |> parse_packet_status_indication(rest)
  end

  defp parse_packet_status_indication(
         indication,
         <<0x10, 0x02, 0x00, call_end_reason::16-little, rest::binary>>
       ) do
    indication
    |> Map.put(:call_end_reason, call_end_reason)
    |> parse_packet_status_indication(rest)
  end

  defp parse_packet_status_indication(
         indication,
         <<0x11, 0x04, 0x00, call_end_reason_type::16-little, call_end_reason::16-little,
           rest::binary>>
       ) do
    indication
    |> Map.put(:call_end_reason_type, parse_call_end_reason_type(call_end_reason_type))
    |> Map.put(:call_end_reason, call_end_reason)
    |> parse_packet_status_indication(rest)
  end

  defp parse_packet_status_indication(indication, <<0x12, 0x01, 0x00, ip_family, rest::binary>>) do
    indication
    |> Map.put(:ip_family, ip_family)
    |> parse_packet_status_indication(rest)
  end

  defp parse_packet_status_indication(
         indication,
         <<0x13, 0x02, 0x00, tech_name::16-little, rest::binary>>
       ) do
    indication
    |> Map.put(:tech_name, parse_tech_name(tech_name))
    |> parse_packet_status_indication(rest)
  end

  defp parse_packet_status_indication(indication, <<0x14, 0x01, 0x00, bearer_id, rest::binary>>) do
    indication
    |> Map.put(:bearer_id, bearer_id)
    |> parse_packet_status_indication(rest)
  end

  defp parse_packet_status_indication(
         indication,
         <<0x15, 0x01, 0x00, xlat_capable, rest::binary>>
       ) do
    indication
    |> Map.put(:xlat_capable, xlat_capable == 1)
    |> parse_packet_status_indication(rest)
  end

  defp parse_packet_status_indication(
         indication,
         <<_type, length::16-little, _values::binary-size(length), rest::binary>>
       ) do
    parse_packet_status_indication(indication, rest)
  end

  defp parse_packet_status(0x01), do: :disconnected
  defp parse_packet_status(0x02), do: :connected
  defp parse_packet_status(0x03), do: :suspended
  defp parse_packet_status(0x04), do: :authenticating

  defp parse_tech_name(0x8001), do: :cdma
  defp parse_tech_name(0x8004), do: :umts
  defp parse_tech_name(0x8020), do: :wlan_local_brkout
  defp parse_tech_name(0x8021), do: :iwlan_s2b
  defp parse_tech_name(0x8880), do: :epc
  defp parse_tech_name(0x8882), do: :embms
  defp parse_tech_name(0x8888), do: :modem_link_local

  defp parse_call_end_reason_type(0x00), do: :unspecified
  defp parse_call_end_reason_type(0x01), do: :mobile_ip
  defp parse_call_end_reason_type(0x02), do: :internal
  defp parse_call_end_reason_type(0x03), do: :call_manager_defined
  defp parse_call_end_reason_type(0x06), do: :three_gpp_specification_defined
  defp parse_call_end_reason_type(0x07), do: :ppp
  defp parse_call_end_reason_type(0x08), do: :ehrpd
  defp parse_call_end_reason_type(0x09), do: :ipv6
  defp parse_call_end_reason_type(0x0C), do: :handoff
end
