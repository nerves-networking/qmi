defmodule QMI.Service.WirelessData do
  use QMI.Service, id: 0x01

  require Logger

  @start_network_interface 0x0020

  def start_network_interface(driver, cp, opts) do
    opts = for {k, v} <- opts, do: {k, format_opt(k, v)}
    # apn_type = opts[:apn_type] || 0

    # tech = Keyword.fetch!(opts, :ext_technology_preference)
    apn = Keyword.fetch!(opts, :apn)
    apn_size = byte_size(apn)

    tlvs = <<0x14, apn_size::little-16, apn::binary>>

    # tlvs = <<0x14, apn_size::little-16, apn::binary, 0x34, 2, 0, tech::little-16, 0x38, 4, 0, apn_type::little-32>>
    tlvs_size = byte_size(tlvs)
    bin = <<@start_network_interface::16-little, tlvs_size::16-little>> <> tlvs

    QMI.Driver.request(driver, bin, cp)
  end

  @impl QMI.Service
  def decode_response_tlvs(%{id: @start_network_interface} = resp) do
    decoded_tlvs = decode_start_network(resp.tlvs, %{})
    %{resp | tlvs: decoded_tlvs}
  end

  def decode_response_tlvs(response) do
    response
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
         <<0x11, 4, 0, call_end_reason_type::little-16, call_end_reason::little-16,
           rest::binary>>,
         acc
       ) do
    type =
      case call_end_reason_type do
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

    acc =
      acc
      |> Map.put(:verbose_end_reason_type, type)
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

    Enum.reverse(acc)
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
end
