defmodule QMI.Codec.NetworkAccess do
  @moduledoc """
  Codec for making network access service requests
  """
  @network_access_service_id 0x03

  # messages
  @get_signal_strength 0x0020
  @get_home_network 0x0025

  # indications
  @serving_system_indication 0x0024

  @typedoc """
  The radio interface that is being reported
  """
  @type radio_interface() :: :no_service | :cdma_1x | :cdma_1x_evdo | :amps | :gsm | :umts | :lte

  @typedoc """
  Report from requesting the signal strength
  """
  @type signal_strength_report() :: %{
          rssi_reports: [%{radio: radio_interface(), rssi: integer()}]
        }

  @typedoc """
  Report from requesting the home network
  """
  @type home_network_report() :: %{
          mcc: char(),
          mnc: char(),
          provider: binary()
        }

  @type serving_system_registration_state() ::
          :not_registered | :registered | :registration_denied | :registration_unknown

  @type attach_state() :: :unknown | :attached | :detached

  @type network() :: :network_unknown | :network_3gpp2 | :network_3gpp

  @typedoc """
  Required fields:

  * `:name` - the name of the indication
  * `:service_id` - the service id
  * `:indication_id` - the indication id
  * `:serving_system_registration_state` - the state of the registration status
    to the serving system
  * `:serving_system_cs_attach_state` - the circuit-switched domain attach state
  * `:serving_system_ps_attach_state` - the packet-switched domain attach state
  * `:serving_system_selected_network` - the type of selected radio access network
  * `:serving_system_radio_interfaces` - a list of raido interfaces currently in use

  Optional fields:

  * `:cell_id` - the id of the cell being used by the connected tower
  * `:timezone_offset` - the UTC offset in seconds
  * `:location_area_code` - the location area code of a tower
  * `:network_datetime` - the reported datetime of the network when connecting
  * `:roaming` - if you are in roaming or not
  * `:daylight_saving_adjustment` - `Calendar.std_offset()` for daylight savings
    adjustment
  """
  @type serving_system_indication() :: %{
          required(:name) => :serving_system_indication,
          required(:service_id) => 0x03,
          required(:indication_id) => 0x0024,
          required(:serving_system_registration_state) => serving_system_registration_state(),
          required(:serving_system_cs_attach_state) => attach_state(),
          required(:serving_system_ps_attach_state) => attach_state(),
          required(:serving_system_selected_network) => network(),
          required(:serving_system_radio_interfaces) => [radio_interface()],
          optional(:cell_id) => integer(),
          optional(:timezone_offset) => Calendar.utc_offset(),
          optional(:location_area_code) => integer(),
          optional(:network_datetime) => NaiveDateTime.t(),
          optional(:roaming) => boolean(),
          optional(:daylight_saving_adjustment) => Calendar.std_offset()
        }

  @doc """
  Make the `QMI.request()` for getting signal strength
  """
  @spec get_signal_strength() :: QMI.request()
  def get_signal_strength() do
    %{
      service_id: @network_access_service_id,
      payload:
        <<@get_signal_strength::16-little, 0x05::little-16, 0x10, 0x02::little-16,
          0xEF::little-16>>,
      decode: &parse_get_signal_strength_resp/1
    }
  end

  defp parse_get_signal_strength_resp(
         <<@get_signal_strength::little-16, _length::little-16, tlvs::binary>>
       ) do
    parse_get_signal_strength_tlvs(%{rssi_reports: []}, tlvs)
  end

  defp parse_get_signal_strength_tlvs(parsed, <<>>) do
    {:ok, parsed}
  end

  defp parse_get_signal_strength_tlvs(
         parsed,
         <<0x11, _length::little-16, num_sets::little-16,
           rssi_list::size(num_sets)-unit(16)-binary, rest::binary>>
       ) do
    rssi_reports =
      for <<rssi, radio_if <- rssi_list>>, do: %{rssi: -rssi, radio: radio_interface(radio_if)}

    parsed
    |> Map.put(:rssi_reports, rssi_reports)
    |> parse_get_signal_strength_tlvs(rest)
  end

  defp parse_get_signal_strength_tlvs(
         parsed,
         <<_type, length::little-16, _values::size(length)-unit(8)-binary, rest::binary>>
       ) do
    parse_get_signal_strength_tlvs(parsed, rest)
  end

  defp radio_interfaces(radio_ifs) do
    for <<radio_if <- radio_ifs>> do
      radio_interface(radio_if)
    end
  end

  defp radio_interface(0x00), do: :no_service
  defp radio_interface(0x01), do: :cdma_1x
  defp radio_interface(0x02), do: :cdma_1x_evdo
  defp radio_interface(0x03), do: :amps
  defp radio_interface(0x04), do: :gsm
  defp radio_interface(0x05), do: :umts
  defp radio_interface(0x08), do: :lte

  @doc """
  Make the request for getting the home network
  """
  @spec get_home_network() :: QMI.request()
  def get_home_network() do
    %{
      service_id: @network_access_service_id,
      payload: <<@get_home_network::little-16, 0x00, 0x00>>,
      decode: &parse_get_home_network_resp/1
    }
  end

  defp parse_get_home_network_resp(
         <<@get_home_network::little-16, size::little-16, tlvs::size(size)-binary>>
       ) do
    parse_get_home_network_tlvs(%{}, tlvs)
  end

  defp parse_get_home_network_resp(_other) do
    {:error, :unexpected_response}
  end

  defp parse_get_home_network_tlvs(parsed, <<>>) do
    {:ok, parsed}
  end

  defp parse_get_home_network_tlvs(
         parsed,
         <<0x01, size::little-16, values::size(size)-binary, rest::binary>>
       ) do
    <<mcc::little-16, mnc::little-16, description::binary>> = values

    parsed
    |> Map.put(:mcc, mcc)
    |> Map.put(:mnc, mnc)
    |> Map.put(:provider, extract_string(description))
    |> parse_get_home_network_tlvs(rest)
  end

  defp parse_get_home_network_tlvs(
         parsed,
         <<_type, length::little-16, _values::size(length)-binary, rest::binary>>
       ) do
    parse_get_home_network_tlvs(parsed, rest)
  end

  defp extract_string(<<length, string::binary-size(length)>>), do: string

  @doc """
  Parse an indication
  """
  @spec parse_indication(binary()) ::
          {:ok, serving_system_indication()} | {:error, :invalid_indication}
  def parse_indication(
        <<@serving_system_indication::16-little, size::16-little, tlvs::binary-size(size)>>
      ) do
    result =
      :serving_system_indication
      |> init_indication()
      |> parse_serving_system_indication(tlvs)

    {:ok, result}
  end

  def parse_indication(_other) do
    {:error, :invalid_indication}
  end

  defp init_indication(:serving_system_indication = name) do
    %{
      name: name,
      indication_id: @serving_system_indication,
      service_id: @network_access_service_id,
      serving_system_registration_state: :not_registered,
      serving_system_cs_attach_state: :unknown,
      serving_system_ps_attach_state: :unknown,
      serving_system_selected_network: :network_unknown,
      serving_system_radio_interfaces: []
    }
  end

  defp parse_serving_system_indication(parsed, <<>>) do
    parsed
  end

  defp parse_serving_system_indication(
         parsed,
         <<0x01, length::16-little, values::size(length)-binary, rest::binary>>
       ) do
    <<registration_state, cs_attach_state, ps_attach_state, selected_network, num_radio_if,
      radio_if::size(num_radio_if)-binary>> = values

    parsed = %{
      parsed
      | serving_system_registration_state: serving_system_registration_state(registration_state),
        serving_system_cs_attach_state: serving_system_attach_state(cs_attach_state),
        serving_system_ps_attach_state: serving_system_attach_state(ps_attach_state),
        serving_system_selected_network: serving_system_network(selected_network),
        serving_system_radio_interfaces: radio_interfaces(radio_if)
    }

    parse_serving_system_indication(parsed, rest)
  end

  defp parse_serving_system_indication(
         serving_system_ind,
         <<0x10, 0x01::little-16, roaming?, rest::binary>>
       ) do
    serving_system_ind
    |> Map.put(:roaming, roaming? == 0)
    |> parse_serving_system_indication(rest)
  end

  defp parse_serving_system_indication(
         serving_system_ind,
         <<0x1E, 0x04::little-16, cell_id::little-32, rest::binary>>
       ) do
    serving_system_ind
    |> Map.put(:cell_id, cell_id)
    |> parse_serving_system_indication(rest)
  end

  defp parse_serving_system_indication(
         serving_system_indication,
         <<0x1A, 0x01::little-16, offset::signed, rest::binary>>
       ) do
    serving_system_indication
    |> Map.put(:timezone_offset, calc_tz_offset(offset))
    |> parse_serving_system_indication(rest)
  end

  defp parse_serving_system_indication(
         serving_system_indication,
         <<0x1B, 0x01::little-16, adjustment, rest::binary>>
       ) do
    serving_system_indication
    |> Map.put(:daylight_saving_adjustment, adjustment * 3600)
    |> parse_serving_system_indication(rest)
  end

  defp parse_serving_system_indication(
         serving_system_indication,
         <<0x1D, 0x02::little-16, lac::little-16, rest::binary>>
       ) do
    serving_system_indication
    |> Map.put(:location_area_code, lac)
    |> parse_serving_system_indication(rest)
  end

  defp parse_serving_system_indication(
         serving_system_indication,
         <<0x1C, 0x08::little-16, year::little-16, month, day, hour, minute, second,
           tz_offset::signed, rest::binary>>
       ) do
    {:ok, datetime} = NaiveDateTime.new(year, month, day, hour, minute, second)

    serving_system_indication
    |> Map.put(:network_datetime, datetime)
    |> Map.put(:timezone_offset, calc_tz_offset(tz_offset))
    |> parse_serving_system_indication(rest)
  end

  defp parse_serving_system_indication(
         parsed,
         <<_type, length::16-little, _values::size(length)-binary, rest::binary>>
       ) do
    parse_serving_system_indication(parsed, rest)
  end

  defp serving_system_registration_state(0x00), do: :not_registered
  defp serving_system_registration_state(0x01), do: :registered
  defp serving_system_registration_state(0x02), do: :registration_denied
  defp serving_system_registration_state(0x04), do: :registration_unknown

  defp serving_system_attach_state(0x00), do: :unknown
  defp serving_system_attach_state(0x01), do: :attached
  defp serving_system_attach_state(0x02), do: :detached

  defp serving_system_network(0x00), do: :network_unknown
  defp serving_system_network(0x01), do: :network_3gpp2
  defp serving_system_network(0x02), do: :network_3gpp

  defp calc_tz_offset(tz_offset), do: tz_offset * 15 * 60
end
