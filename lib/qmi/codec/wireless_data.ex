defmodule QMI.Codec.WirelessData do
  @moduledoc """
  Codec for making wireless data service requests
  """

  import Bitwise

  @event_report 0x0001
  @start_network_interface 0x0020
  @packet_service_status_ind 0x0022
  @modify_profile_settings 0x0028

  # When a stat is configured to be reported but no data has been recorded
  # before the indication is sent, the value is `0xFFFFFFFF` which is treated as
  # a missing value in many other places in the specification. Using libqmi as a
  # reference we use this value to check if the value is missing.
  # https://gitlab.freedesktop.org/mobile-broadband/libqmi/-/blob/master/src/qmicli/qmicli-wds.c#L1068-1091
  @missing_stat_value 0xFFFFFFFF

  @typedoc """
  Options for whens starting a network interface

  * `:apn` - the name of our APN
  """
  @type start_network_interface_opt() :: {:apn, String.t()} | {:profile_3gpp_index, integer()}

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

  @typedoc """
  The indication for the wireless data service's event report

  To configure what information is sent through this indication see
  set_event_report/1`.
  """
  @type event_report_indication() :: %{
          required(:name) => :event_report_indication,
          optional(:tx_bytes) => integer(),
          optional(:rx_bytes) => integer(),
          optional(:tx_packets) => integer(),
          optional(:rx_packets) => integer(),
          optional(:tx_overflows) => integer(),
          optional(:rx_overflows) => integer(),
          optional(:tx_errors) => integer(),
          optional(:rx_errors) => integer(),
          optional(:tx_drops) => integer(),
          optional(:rx_drops) => integer()
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

  defp make_tlvs([{:profile_3gpp_index, profile_index} | rest], tlvs, size) do
    tlv = <<0x31, 0x01::little-16, profile_index>>
    make_tlvs(rest, [tlvs, tlv], size + byte_size(tlv))
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
          {:ok, packet_status_indication() | event_report_indication()}
          | {:error, :invalid_indication}
  def parse_indication(
        <<@packet_service_status_ind::16-little, size::16-little, tlvs::binary-size(size)>>
      ) do
    result = parse_packet_status_indication(packet_status_indication_init(), tlvs)

    {:ok, result}
  end

  def parse_indication(<<@event_report::little-16, size::16-little, tlvs::binary-size(size)>>) do
    {:ok, parse_event_report_indication(%{name: :event_report_indication}, tlvs)}
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

  def parse_event_report_indication(event_report_indication, <<>>), do: event_report_indication

  def parse_event_report_indication(
        event_report_indication,
        <<0x10, 0x04::little-16, tx_packets_count::little-32, rest::binary>>
      ) do
    tx_packets = get_stat_value(tx_packets_count)

    event_report_indication
    |> Map.put(:tx_packets, tx_packets)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<0x11, 0x04::little-16, rx_packets_count::little-32, rest::binary>>
      ) do
    rx_packets = get_stat_value(rx_packets_count)

    event_report_indication
    |> Map.put(:rx_packets, rx_packets)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<0x12, 0x04::little-16, tx_error_count::little-32, rest::binary>>
      ) do
    tx_errors = get_stat_value(tx_error_count)

    event_report_indication
    |> Map.put(:tx_errors, tx_errors)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<0x13, 0x04::little-16, rx_error_count::little-32, rest::binary>>
      ) do
    rx_errors = get_stat_value(rx_error_count)

    event_report_indication
    |> Map.put(:rx_errors, rx_errors)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<0x14, 0x04::little-16, tx_overflow_count::little-32, rest::binary>>
      ) do
    tx_overflows = get_stat_value(tx_overflow_count)

    event_report_indication
    |> Map.put(:tx_overflows, tx_overflows)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<0x15, 0x04::little-16, rx_overflow_count::little-32, rest::binary>>
      ) do
    rx_overflows = get_stat_value(rx_overflow_count)

    event_report_indication
    |> Map.put(:rx_overflows, rx_overflows)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<0x19, 0x08::little-16, tx_byte_count::little-64, rest::binary>>
      ) do
    event_report_indication
    |> Map.put(:tx_bytes, tx_byte_count)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<0x1A, 0x08::little-16, rx_byte_count::little-64, rest::binary>>
      ) do
    event_report_indication
    |> Map.put(:rx_bytes, rx_byte_count)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<0x25, 0x04::little-16, tx_packets_dropped::little-32, rest::binary>>
      ) do
    tx_drops = get_stat_value(tx_packets_dropped)

    event_report_indication
    |> Map.put(:tx_drops, tx_drops)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<0x26, 0x04::little-16, rx_packets_dropped::little-32, rest::binary>>
      ) do
    rx_drops = get_stat_value(rx_packets_dropped)

    event_report_indication
    |> Map.put(:rx_drops, rx_drops)
    |> parse_event_report_indication(rest)
  end

  def parse_event_report_indication(
        event_report_indication,
        <<_type, length::little-16, _values::binary-size(length), rest::binary>>
      ) do
    parse_event_report_indication(event_report_indication, rest)
  end

  defp get_stat_value(value) when value == @missing_stat_value, do: 0
  defp get_stat_value(value), do: value

  @typedoc """
  The type of measurement you are wanting to be reported

  * `:tx_bytes` - number of bytes transmitted
  * `:rx_bytes` - number of bytes received
  * `:tx_packets` - number of transmit packets sent without error
  * `:rx_packets` - number of packets received without error
  * `:tx_overflows` - number of packets dropped due to tx buffer
    overflowed (out of memory)
  * `:rx_overflows` - number of packets dropped due to rx buffer
    overflowed (out of memory)
  * `:tx_errors` - number of outgoing packets with framing errors
  * `:rx_errors` - number of incoming packets with framing errors
  * `:tx_drops` - number outgoing packets dropped
  * `:rx_drops` - number incoming packets dropped
  """
  @type statistic_measurement() ::
          :tx_bytes
          | :rx_bytes
          | :tx_packets
          | :rx_packets
          | :tx_overflows
          | :rx_overflows
          | :tx_errors
          | :rx_errors
          | :tx_drops
          | :rx_drops

  @typedoc """
  Options for the wireless data event report configuration

  * `:statistics_interval` - an interval in seconds on when to report statistics
    about transmit and receive operations
  * `:statistics` - list which statistic measurements to report

  For transmit and receive statistics, if no interval is provided the default is
  60 seconds. If the `:statistics` option is not provided it will default to
  `:all`. The report is only sent in the interval if there was a change in any
  of the statistics. So, if no changes took place the report will be skipped for
  an interval.

  To configure event report to not included any stats pass `:none` to
  the `:statistics` option.
  """
  @type event_report_opt() ::
          {:statistics_interval, non_neg_integer()}
          | {:statistics, [statistic_measurement()] | :all | :none}

  @doc """
  Request to set the wireless data services event report options
  """
  @spec set_event_report([event_report_opt()]) :: QMI.request()
  def set_event_report(opts \\ []) do
    tlvs = make_tlvs(opts)
    length = byte_size(tlvs)

    payload = [<<@event_report::little-16, length::little-16>>, tlvs]

    %{service_id: 0x01, payload: payload, decode: &parse_set_event_response/1}
  end

  defp make_tlvs(opts) do
    case opts[:statistics] do
      :none ->
        <<>>

      stats ->
        # if no stats are specified we will get them all
        default_stats = stats || :all
        interval = opts[:statistics_interval] || 60
        mask = statistics_mask(default_stats)

        <<0x11, 0x05::little-16, interval, mask::little-32>>
    end
  end

  def statistics_mask(:all) do
    0x03FF
  end

  def statistics_mask(stats) do
    for stat <- stats, reduce: 0 do
      mask ->
        stat_to_integer(stat) ||| mask
    end
  end

  def stat_to_integer(:tx_packets), do: 0x01
  def stat_to_integer(:rx_packets), do: 0x02
  def stat_to_integer(:tx_errors), do: 0x04
  def stat_to_integer(:rx_errors), do: 0x08
  def stat_to_integer(:tx_overflows), do: 0x10
  def stat_to_integer(:rx_overflows), do: 0x20
  def stat_to_integer(:tx_bytes), do: 0x40
  def stat_to_integer(:rx_bytes), do: 0x80
  def stat_to_integer(:tx_drops), do: 0x0100
  def stat_to_integer(:rx_drops), do: 0x0200

  defp parse_set_event_response(
         <<@event_report::little-16, size::little-16, _values::binary-size(size)>>
       ) do
    :ok
  end

  @typedoc """
  The profile technology type
  """
  @type profile_type() :: :profile_type_3gpp | :profile_type_3gpp2 | :profile_type_epc

  @typedoc """
  The profile settings

  * `:roaming_disallowed` - if using roaming is allowed or not
  * `:profile_type` - the profile type - see `profile_type()` type docs for more
    information
  """
  @type profile_setting() :: {:roaming_disallowed, boolean()} | {:profile_type, profile_type()}

  @typedoc """
  Response from issuing a modify profile settings request
  """
  @type modify_profile_settings_response() :: %{extended_error_code: integer() | nil}

  @doc """
  Modify the QMI profile setting

  When providing the profile settings if `:profile_type` is not included this
  function will default to `:profile_type_3gpp`
  """
  @spec modify_profile_settings(profile_index :: integer(), [profile_setting()]) :: QMI.request()
  def modify_profile_settings(index, settings) do
    profile_type = settings[:profile_type] || :profile_type_3gpp
    settings = Keyword.put(settings, :profile_info, {index, profile_type})

    {tlvs, tlvs_byte_size} = make_modify_profile_settings_tlvs(settings, [], 0)

    %{
      service_id: 0x01,
      payload: [
        <<@modify_profile_settings::little-16, tlvs_byte_size::little-16>>,
        tlvs
      ],
      decode: &parse_modify_profile_settings_resp/1
    }
  end

  defp make_modify_profile_settings_tlvs([], encoded, total_size) do
    {encoded, total_size}
  end

  defp make_modify_profile_settings_tlvs(
         [{:profile_info, {profile_index, type}} | rest],
         encoded,
         size
       ) do
    type_byte = encode_profile_type(type)
    encoded_tlv = <<0x01, 0x02::little-16, type_byte, profile_index>>

    make_modify_profile_settings_tlvs(
      rest,
      encoded ++ [encoded_tlv],
      size + byte_size(encoded_tlv)
    )
  end

  defp make_modify_profile_settings_tlvs(
         [{:roaming_disallowed, disallowed?} | rest],
         encoded,
         size
       ) do
    disallowed_byte = if disallowed?, do: 0x01, else: 0x00

    tlvs = <<0x3E, 0x01::little-16, disallowed_byte>>

    make_modify_profile_settings_tlvs(rest, encoded ++ [tlvs], size + byte_size(tlvs))
  end

  defp make_modify_profile_settings_tlvs([_unknown | rest], encoded, size) do
    make_modify_profile_settings_tlvs(rest, encoded, size)
  end

  defp encode_profile_type(:profile_type_3gpp), do: 0x00
  defp encode_profile_type(:profile_type_3gpp2), do: 0x01
  defp encode_profile_type(:profile_type_epc), do: 0x02

  defp parse_modify_profile_settings_resp(
         <<@modify_profile_settings::little-16, size::little-16, values::binary-size(size)>>
       ) do
    result = parse_profile_settings_resp_tlvs(values, %{extended_error_code: nil})
    {:ok, result}
  end

  defp parse_profile_settings_resp_tlvs(<<>>, parsed) do
    parsed
  end

  defp parse_profile_settings_resp_tlvs(<<0>>, parsed) do
    parsed
  end

  defp parse_profile_settings_resp_tlvs(
         <<0xE0, 0x02::little-16, code::little-16, rest::binary>>,
         parsed
       ) do
    parsed = Map.put(parsed, :extended_error_code, code)

    parse_profile_settings_resp_tlvs(rest, parsed)
  end

  defp parse_profile_settings_resp_tlvs(
         <<_type, len::little, _value::binary-size(len), rest::binary>>,
         parsed
       ) do
    parse_profile_settings_resp_tlvs(rest, parsed)
  end
end
