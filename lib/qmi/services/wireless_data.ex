defmodule QMI.Service.WirelessData do
  use QMI.Service, id: 0x01

  require Logger

  @start_network_interface 0x0020
  @pkt_srvc_status 0x0022
  @get_runtime_settings 0x002D

  def get_pkt_srvc_status(device, cp) do
    case QMI.Driver.request(device, <<@pkt_srvc_status::little-16, 0, 0>>, cp) do
      {:ok, msg} -> msg.tlvs.connection_status
      err -> err
    end
  end

  def get_runtime_settings(device, cp) do
    case QMI.Driver.request(device, <<@get_runtime_settings::little-16, 0, 0>>, cp) do
      {:ok, msg} -> msg.tlvs
      err -> err
    end
  end

  def start_network_interface(device, cp, opts) do
    opts = for {k, v} <- opts, do: {k, format_opt(k, v)}
    # apn_type = opts[:apn_type] || 0

    # tech = Keyword.fetch!(opts, :ext_technology_preference)
    apn = Keyword.fetch!(opts, :apn)
    apn_size = byte_size(apn)

    tlvs = <<0x14, apn_size::little-16, apn::binary>>

    # tlvs = <<0x14, apn_size::little-16, apn::binary, 0x34, 2, 0, tech::little-16, 0x38, 4, 0, apn_type::little-32>>
    tlvs_size = byte_size(tlvs)
    bin = <<@start_network_interface::16-little, tlvs_size::16-little>> <> tlvs

    QMI.Driver.request(device, bin, cp)
  end

  @impl QMI.Service
  def decode_response_tlvs(%{id: @start_network_interface} = resp) do
    decoded_tlvs = decode_start_network(resp.tlvs, %{})
    %{resp | tlvs: decoded_tlvs}
  end

  def decode_response_tlvs(%{id: @pkt_srvc_status} = resp) do
    tlvs = decode_pkt_status(resp.tlvs, %{})
    %{resp | tlvs: tlvs}
  end

  def decode_response_tlvs(%{id: @get_runtime_settings} = resp) do
    tlvs = decode_runtime_settings(resp.tlvs, %{})
    %{resp | tlvs: tlvs}
  end

  def decode_response_tlvs(response) do
    response
  end

  defp call_end_reason(cer) do
    # TODO: Get specific call_end_reason
    cer
  end

  defp call_end_reason_type(cert) do
    case cert do
      0 -> :unspecified
      1 -> :mobile_ip
      2 -> :internal
      3 -> :call_manager_defined
      6 -> :spec_defined_3gpp
      7 -> :ppp
      8 -> :ehrpd
      9 -> :ipv6
      0x0C -> :handoff
    end
  end

  defp connection_status(conn_status) do
    case conn_status do
      1 -> :disconnected
      2 -> :connected
      3 -> :suspended
      4 -> :authenticating
    end
  end

  defp decode_pkt_status(<<1, 1, 0, conn_status>>, _) do
    %{connection_status: connection_status(conn_status)}
  end

  defp decode_pkt_status(<<1, 2, 0, conn_status, reconfig?, rest::binary>>, acc) do
    acc =
      acc
      |> Map.put(:connection_status, connection_status(conn_status))
      |> Map.put(:reconfiguration_required?, reconfig? != 0)

    decode_pkt_status(rest, acc)
  end

  defp decode_pkt_status(<<0x10, 2, 0, cer::little-16, rest::binary>>, acc) do
    decode_pkt_status(rest, Map.put(acc, :call_end_reason, call_end_reason(cer)))
  end

  defp decode_pkt_status(<<0x11, 4, 0, cert::little-16, cer::little-16, rest::binary>>, acc) do
    acc =
      acc
      |> Map.put(:verbose_end_reason_type, call_end_reason_type(cert))
      |> Map.put(:verbose_end_reason, call_end_reason(cer))

    decode_pkt_status(rest, acc)
  end

  defp decode_pkt_status(<<0x12, 1, 0, ip_family, rest::binary>>, acc) do
    decode_pkt_status(rest, Map.put(acc, :ip_family, :"ipv#{ip_family}"))
  end

  defp decode_pkt_status(<<0x13, 2, 0, tname::signed-little-16, rest::binary>>, acc) do
    acc = Map.put(acc, :tech_name, tech_name(tname))
    decode_pkt_status(rest, acc)
  end

  defp decode_pkt_status(<<0x14, 1, 0, bearer_id, rest::binary>>, acc) do
    acc = Map.put(acc, :bearer_id, bearer_id)
    decode_pkt_status(rest, acc)
  end

  defp decode_pkt_status(<<0x15, 1, 0, xlat, rest::binary>>, acc) do
    acc = Map.put(acc, :xlat_capable?, xlat == 1)
    decode_pkt_status(rest, acc)
  end

  defp decode_pkt_status(rem, acc) do
    if byte_size(rem) > 0 do
      Logger.warn("[WDS] pkt_status has unmatched bytes remaining- #{inspect(rem)}")
    end

    acc
  end

  defp decode_start_network(<<1, 4, 0, pkt_data_handle::little-32, rest::binary>>, acc) do
    # acc = [%{pkt_data_handle: pkt_data_handle} | acc]
    acc = Map.put(acc, :pkt_data_handle, pkt_data_handle)
    decode_start_network(rest, acc)
  end

  defp decode_start_network(<<0x10, 2, 0, call_end_reason::little-16, rest::binary>>, acc) do
    acc = Map.put(acc, :call_end_reason, call_end_reason)
    decode_start_network(rest, acc)
  end

  defp decode_start_network(
         <<0x11, 4, 0, cert::little-16, call_end_reason::little-16, rest::binary>>,
         acc
       ) do
    acc =
      acc
      |> Map.put(:verbose_end_reason_type, call_end_reason_type(cert))
      |> Map.put(:verbose_end_reason, call_end_reason)

    decode_start_network(rest, acc)
  end

  defp decode_start_network(
         <<0x12, 8, 0, ep_type::little-32, iface_id::little-32, rest::binary>>,
         acc
       ) do
    ep_type =
      case ep_type do
        0 -> :reserved
        1 -> :hsic
        2 -> :hsusb
        3 -> :pcie
        4 -> :embedded
        5 -> :dmux
      end

    acc =
      acc
      |> Map.put(:ep_type, ep_type)
      |> Map.put(:iface_id, iface_id)

    decode_start_network(rest, acc)
  end

  defp decode_start_network(<<0x13, 1, 0, mux_id, rest::binary>>, acc) do
    acc = Map.put(acc, :mux_id, mux_id)
    decode_start_network(rest, acc)
  end

  defp decode_start_network(rem, acc) do
    if byte_size(rem) > 0 do
      Logger.warn("[WDS] start_network has unmatched bytes remaining- #{inspect(rem)}")
    end

    acc
  end

  defp decode_runtime_settings(<<0x14, len::little-16, apn::binary-size(len), rest::binary>>, acc) do
    decode_runtime_settings(rest, Map.put(acc, :apn, apn))
  end

  defp decode_runtime_settings(<<0x15, 4, 0, d, c, b, a, rest::binary>>, acc) do
    acc = Map.put(acc, :primary_dns, {a, b, c, d})
    decode_runtime_settings(rest, acc)
  end

  defp decode_runtime_settings(<<0x16, 4, 0, d, c, b, a, rest::binary>>, acc) do
    acc = Map.put(acc, :secondary_dns, {a, b, c, d})
    decode_runtime_settings(rest, acc)
  end

  defp decode_runtime_settings(<<0x1E, 4, 0, d, c, b, a, rest::binary>>, acc) do
    acc = Map.put(acc, :ipv4_address, {a, b, c, d})
    decode_runtime_settings(rest, acc)
  end

  defp decode_runtime_settings(<<0x1F, 2, 0, ptype, pindex, rest::binary>>, acc) do
    type =
      case ptype do
        0 -> :"3GPP"
        1 -> :"3GPP2"
        2 -> :EPC
      end

    acc =
      acc
      |> Map.put(:profile_type, type)
      |> Map.put(:profile_index, pindex)

    decode_runtime_settings(rest, acc)
  end

  defp decode_runtime_settings(<<0x20, 4, 0, d, c, b, a, rest::binary>>, acc) do
    acc = Map.put(acc, :gateway, {a, b, c, d})
    decode_runtime_settings(rest, acc)
  end

  defp decode_runtime_settings(<<0x21, 4, 0, d, c, b, a, rest::binary>>, acc) do
    acc = Map.put(acc, :subnet_mask, {a, b, c, d})
    decode_runtime_settings(rest, acc)
  end

  defp decode_runtime_settings(<<t, l::little-16, v::binary-size(l), rest::binary>>, acc) do
    Logger.warn(
      "[WDS] get_runtime_settings has unmatched TLV- type: #{t}, length: #{l}, value: #{
        inspect(v)
      }"
    )

    decode_runtime_settings(rest, acc)
  end

  defp decode_runtime_settings("", acc) do
    acc
  end

  defp format_opt(:ext_technology_preference, e) do
    case e do
      e when is_integer(e) -> e
      :CDMA -> 32767
      :UMTS -> 32764
      :eMBMS -> 30590
      :modem_link_local -> 30584
      :non_ip -> 30588
    end
  end

  defp format_opt(:apn_type, t) do
    case t do
      t when is_integer(t) and t <= 3 -> t
      :unspecified -> 0
      :internet -> 1
      :ims -> 2
      :vsim -> 3
    end
  end

  defp format_opt(_k, opt), do: opt

  defp tech_name(tname) do
    case abs(tname) do
      32767 -> :CDMA
      32764 -> :UMTS
      32736 -> :wlan_local_brkout
      32735 -> :iwlan_s2b
      30590 -> :eMBMS
      30592 -> :epc
      30584 -> :modem_link_local
      30588 -> :non_ip
    end
  end
end
