defmodule QMI.WirelessData.StartNetworkInterfaceResp do
  @moduledoc """
  Response to the start network interface request

  This response is received after the data session is connected and the device
  can then perform IP address configuration.
  """

  @type call_end_reason_type() ::
          :unspecified
          | :mobile_ip
          | :internal
          | :call_manager_defined
          | :spec_defined_3gpp
          | :ppp
          | :ehrpd
          | :ipv6
          | :handoff

  @type endpoint() :: :reserved | :hsic | :hsusb | :pcie | :embedded | :dmux

  @type t() :: %__MODULE__{
          packet_data_handle: non_neg_integer(),
          call_end_reason: non_neg_integer() | nil,
          call_end_reason_type: call_end_reason_type() | nil,
          endpoint_type: endpoint() | nil,
          iface_id: non_neg_integer() | nil,
          mux_id: non_neg_integer() | nil
        }

  defstruct packet_data_handle: nil,
            call_end_reason: nil,
            call_end_reason_type: nil,
            endpoint_type: nil,
            iface_id: nil,
            mux_id: nil

  defimpl QMI.Response do
    alias QMI.WirelessData.StartNetworkInterfaceResp

    def parse_tlvs(response, binary) do
      do_parse_tlvs(response, binary)
    end

    defp do_parse_tlvs(response, <<>>) do
      response
    end

    defp do_parse_tlvs(response, <<0x01, 0x04::little-16, pkt_handle::little-32, rest::binary>>) do
      response = %StartNetworkInterfaceResp{response | packet_data_handle: pkt_handle}

      do_parse_tlvs(response, rest)
    end

    defp do_parse_tlvs(response, <<0x10, 0x02::little-16, end_reason::little-16, rest::binary>>) do
      response = %StartNetworkInterfaceResp{response | call_end_reason: end_reason}
      do_parse_tlvs(response, rest)
    end

    defp do_parse_tlvs(
           response,
           <<0x11, 0x04::little-16, cert::little-16, end_reason::little-16, rest::binary>>
         ) do
      response = %StartNetworkInterfaceResp{
        response
        | call_end_reason: end_reason,
          call_end_reason_type: call_end_reason_type(cert)
      }

      do_parse_tlvs(response, rest)
    end

    defp do_parse_tlvs(
           response,
           <<0x12, 0x08::little-16, ep_type::little-32, iface_id::little-32, rest::binary>>
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

      response = %StartNetworkInterfaceResp{response | endpoint_type: ep_type, iface_id: iface_id}

      do_parse_tlvs(response, rest)
    end

    defp do_parse_tlvs(response, <<0x13, 0x01::little-16, mux_id, rest::binary>>) do
      response = %StartNetworkInterfaceResp{response | mux_id: mux_id}

      do_parse_tlvs(response, rest)
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
  end
end
