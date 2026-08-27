# SPDX-FileCopyrightText: 2025 Marc Lainez
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.Codec.WirelessDataAdmin do
  @moduledoc """
  Codec for the QMI WDA (Wireless Data Administrative) service.

  The WDA service configures the data format used between the modem and the
  host driver.  On modems whose `qmi_wwan` driver does not expose
  `/sys/class/net/<ifname>/qmi/raw_ip`, this is the only way to switch the
  data path between 802.3 (Ethernet) framing and raw-IP framing.
  """

  @wda_service_id 0x1A

  @set_data_format 0x0020
  @get_data_format 0x0021

  @typedoc """
  Link-layer protocol for the data path.

  * `:raw_ip` – raw IP packets (no Ethernet header)
  * `:"802.3"` – Ethernet-framed packets
  """
  @type link_layer_protocol :: :raw_ip | :"802.3" | :unknown

  @typedoc """
  Data aggregation protocol.

  * `:disabled` – no aggregation
  * `:qmap_v1` – QMAP version 1
  * `:qmap_v5` – QMAP version 5
  """
  @type aggregation_protocol :: :disabled | :qmap_v1 | :qmap_v5 | :unknown

  @typedoc """
  Result of `get_data_format/0` or `set_data_format/1`.
  """
  @type data_format :: %{
          optional(:qos_format) => boolean(),
          optional(:link_layer_protocol) => link_layer_protocol(),
          optional(:ul_aggregation_protocol) => aggregation_protocol(),
          optional(:dl_aggregation_protocol) => aggregation_protocol(),
          optional(:dl_max_datagrams) => non_neg_integer(),
          optional(:dl_max_size) => non_neg_integer()
        }

  @typedoc """
  Options for `set_data_format/1`.

  * `:link_layer_protocol` – `:raw_ip` or `:"802.3"` (required)
  * `:ul_aggregation_protocol` – uplink aggregation (default `:disabled`)
  * `:dl_aggregation_protocol` – downlink aggregation (default `:disabled`)
  * `:qos_format` – whether to include QoS headers (default `false`)
  * `:endpoint_type` – endpoint device type (default `2` for HSUSB)
  * `:endpoint_iface_number` – interface number on the endpoint
  """
  @type set_data_format_opt ::
          {:link_layer_protocol, link_layer_protocol()}
          | {:ul_aggregation_protocol, aggregation_protocol()}
          | {:dl_aggregation_protocol, aggregation_protocol()}
          | {:qos_format, boolean()}
          | {:endpoint_type, non_neg_integer()}
          | {:endpoint_iface_number, non_neg_integer()}

  # -- Public API ------------------------------------------------------------

  @doc """
  Build a request to query the current data format.
  """
  @spec get_data_format() :: QMI.request()
  def get_data_format do
    %{
      service_id: @wda_service_id,
      payload: [<<@get_data_format::little-16, 0::little-16>>],
      decode: &parse_data_format_response(@get_data_format, &1)
    }
  end

  @doc """
  Build a request to set the data format.

  ## Examples

      QMI.Codec.WirelessDataAdmin.set_data_format(link_layer_protocol: :raw_ip)
  """
  @spec set_data_format([set_data_format_opt()]) :: QMI.request()
  def set_data_format(opts) do
    {tlvs, size} = build_set_data_format_tlvs(opts, [], 0)

    %{
      service_id: @wda_service_id,
      payload: [<<@set_data_format::little-16, size::little-16>>, tlvs],
      decode: &parse_data_format_response(@set_data_format, &1)
    }
  end

  # -- TLV builders ----------------------------------------------------------

  defp build_set_data_format_tlvs([], tlvs, size), do: {tlvs, size}

  defp build_set_data_format_tlvs([{:qos_format, qos?} | rest], tlvs, size) do
    val = if qos?, do: 1, else: 0
    tlv = <<0x10, 0x01::little-16, val>>
    build_set_data_format_tlvs(rest, [tlvs, tlv], size + byte_size(tlv))
  end

  defp build_set_data_format_tlvs([{:link_layer_protocol, proto} | rest], tlvs, size) do
    val = encode_link_layer_protocol(proto)
    tlv = <<0x11, 0x04::little-16, val::little-32>>
    build_set_data_format_tlvs(rest, [tlvs, tlv], size + byte_size(tlv))
  end

  defp build_set_data_format_tlvs([{:ul_aggregation_protocol, proto} | rest], tlvs, size) do
    val = encode_aggregation_protocol(proto)
    tlv = <<0x12, 0x04::little-16, val::little-32>>
    build_set_data_format_tlvs(rest, [tlvs, tlv], size + byte_size(tlv))
  end

  defp build_set_data_format_tlvs([{:dl_aggregation_protocol, proto} | rest], tlvs, size) do
    val = encode_aggregation_protocol(proto)
    tlv = <<0x13, 0x04::little-16, val::little-32>>
    build_set_data_format_tlvs(rest, [tlvs, tlv], size + byte_size(tlv))
  end

  defp build_set_data_format_tlvs(
         [{:endpoint_type, type} | rest],
         tlvs,
         size
       ) do
    # TLV 0x17: Endpoint info — we store type now, iface_number comes next
    # This is handled specially: we look ahead for :endpoint_iface_number
    {iface_number, rest} = pop_opt(rest, :endpoint_iface_number, 0)
    tlv = <<0x17, 0x08::little-16, type::little-32, iface_number::little-32>>
    build_set_data_format_tlvs(rest, [tlvs, tlv], size + byte_size(tlv))
  end

  defp build_set_data_format_tlvs([{:endpoint_iface_number, iface_number} | rest], tlvs, size) do
    # If endpoint_iface_number appears without endpoint_type before it,
    # default endpoint_type to 2 (HSUSB)
    tlv = <<0x17, 0x08::little-16, 2::little-32, iface_number::little-32>>
    build_set_data_format_tlvs(rest, [tlvs, tlv], size + byte_size(tlv))
  end

  defp build_set_data_format_tlvs([_unknown | rest], tlvs, size) do
    build_set_data_format_tlvs(rest, tlvs, size)
  end

  defp pop_opt(opts, key, default) do
    case Keyword.pop(opts, key) do
      {nil, rest} -> {default, rest}
      {val, rest} -> {val, rest}
    end
  end

  # -- Response parsing ------------------------------------------------------

  defp parse_data_format_response(
         msg_id,
         <<msg_id::little-16, _size::little-16, 0x02, _result_len::little-16, 0x00::little-16,
           0x00::little-16, rest::binary>>
       ) do
    {:ok, parse_data_format_tlvs(rest, %{})}
  end

  defp parse_data_format_response(
         msg_id,
         <<msg_id::little-16, _size::little-16, 0x02, _result_len::little-16,
           _qmi_error::little-16, error_code::little-16, _rest::binary>>
       ) do
    {:error, QMI.Codes.decode_error_code(error_code)}
  end

  defp parse_data_format_response(_msg_id, _bin) do
    {:error, :parse_error}
  end

  # -- Optional TLV parsing --------------------------------------------------

  defp parse_data_format_tlvs(<<>>, acc), do: acc

  defp parse_data_format_tlvs(
         <<0x10, 0x01::little-16, qos, rest::binary>>,
         acc
       ) do
    parse_data_format_tlvs(rest, Map.put(acc, :qos_format, qos != 0))
  end

  defp parse_data_format_tlvs(
         <<0x11, 0x04::little-16, proto::little-32, rest::binary>>,
         acc
       ) do
    parse_data_format_tlvs(
      rest,
      Map.put(acc, :link_layer_protocol, decode_link_layer_protocol(proto))
    )
  end

  defp parse_data_format_tlvs(
         <<0x12, 0x04::little-16, proto::little-32, rest::binary>>,
         acc
       ) do
    parse_data_format_tlvs(
      rest,
      Map.put(acc, :ul_aggregation_protocol, decode_aggregation_protocol(proto))
    )
  end

  defp parse_data_format_tlvs(
         <<0x13, 0x04::little-16, proto::little-32, rest::binary>>,
         acc
       ) do
    parse_data_format_tlvs(
      rest,
      Map.put(acc, :dl_aggregation_protocol, decode_aggregation_protocol(proto))
    )
  end

  defp parse_data_format_tlvs(
         <<0x15, 0x04::little-16, max_datagrams::little-32, rest::binary>>,
         acc
       ) do
    parse_data_format_tlvs(rest, Map.put(acc, :dl_max_datagrams, max_datagrams))
  end

  defp parse_data_format_tlvs(
         <<0x16, 0x04::little-16, max_size::little-32, rest::binary>>,
         acc
       ) do
    parse_data_format_tlvs(rest, Map.put(acc, :dl_max_size, max_size))
  end

  # Skip unknown TLVs
  defp parse_data_format_tlvs(
         <<_tag, len::little-16, _value::binary-size(len), rest::binary>>,
         acc
       ) do
    parse_data_format_tlvs(rest, acc)
  end

  # -- Encoders / Decoders ---------------------------------------------------

  defp encode_link_layer_protocol(:raw_ip), do: 2
  defp encode_link_layer_protocol(:"802.3"), do: 1

  defp decode_link_layer_protocol(1), do: :"802.3"
  defp decode_link_layer_protocol(2), do: :raw_ip
  defp decode_link_layer_protocol(_), do: :unknown

  defp encode_aggregation_protocol(:disabled), do: 0
  defp encode_aggregation_protocol(:qmap_v1), do: 5
  defp encode_aggregation_protocol(:qmap_v5), do: 6

  defp decode_aggregation_protocol(0), do: :disabled
  defp decode_aggregation_protocol(5), do: :qmap_v1
  defp decode_aggregation_protocol(6), do: :qmap_v5
  defp decode_aggregation_protocol(_), do: :unknown
end
