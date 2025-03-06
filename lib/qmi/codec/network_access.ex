# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Matt Ludwigs
# SPDX-FileCopyrightText: 2023 Liv Cella
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.Codec.NetworkAccess do
  @moduledoc """
  Codec for making network access service requests
  """
  import Bitwise

  require Logger

  @network_access_service_id 0x03

  # messages
  @get_signal_strength 0x0020
  @get_home_network 0x0025
  @get_rf_band_info 0x0031
  @set_system_selection_preference 0x0033
  @get_system_selection_preference 0x0034
  @get_cell_location_info 0x0043
  @get_sys_info 0x004D

  # indications
  @serving_system_indication 0x0024
  @operator_name_indication 0x003A

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

  @typedoc """
  Information about an radio interface band
  """
  @type rf_band_information() :: %{
          interface: radio_interface(),
          band: binary(),
          channel: integer()
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
  * `:serving_system_radio_interfaces` - a list of radio interfaces currently in use

  Optional fields:

  * `:cell_id` - the id of the cell being used by the connected tower
  * `:utc_offset` - the UTC offset in seconds
  * `:location_area_code` - the location area code of a tower
  * `:network_datetime` - the reported datetime of the network when connecting
  * `:roaming` - if you are in roaming or not
  * `:std_offset` - `Calendar.std_offset()` for daylight savings
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
          optional(:utc_offset) => Calendar.utc_offset(),
          optional(:location_area_code) => integer(),
          optional(:network_datetime) => NaiveDateTime.t(),
          optional(:roaming) => boolean(),
          optional(:std_offset) => Calendar.std_offset()
        }

  @type operator_name_indication() :: %{
          name: :operator_name_indication,
          long_name: binary(),
          short_name: binary()
        }

  @typedoc """
  How long a system preference change should be applied

  * `:power_cycle` - only remains active until the next power cycle
  * `:permanent` - remains active through power cycles until changed by a client
  """
  @type preference_change_duration() :: :power_cycle | :permanent

  @typedoc """
  The options to configure the system selection preference

  * `:mode_preference` - which radio access technologies should the modem use
  * `:change_duration` - the `preference_change_duration()` for the applied
    settings. The default is `:permanent`.
  * `:roaming_preference` - the preferred roaming setting
  """
  @type set_system_selection_preference_opt() ::
          {:mode_preference, [radio_interface()]}
          | {:change_duration, preference_change_duration()}
          | {:roaming_preference, roaming_preference()}

  @doc """
  Make the `QMI.request()` for getting signal strength
  """
  @spec get_signal_strength() :: QMI.request()
  def get_signal_strength() do
    %{
      service_id: @network_access_service_id,
      payload:
        <<@get_signal_strength::little-16, 0x05::little-16, 0x10, 0x02::little-16,
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
           rssi_list::binary-size(num_sets)-unit(16), rest::binary>>
       ) do
    rssi_reports =
      for <<rssi, radio_if <- rssi_list>>, do: %{rssi: -rssi, radio: radio_interface(radio_if)}

    parsed
    |> Map.put(:rssi_reports, rssi_reports)
    |> parse_get_signal_strength_tlvs(rest)
  end

  defp parse_get_signal_strength_tlvs(
         parsed,
         <<_type, length::little-16, _values::binary-size(length)-unit(8), rest::binary>>
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
  defp radio_interface(0x09), do: :td_scdma

  @typedoc """
  Cell set

  * `:pci` - Physical cell ID
  * `:rsrq` - Current RSRQ in 1/10 dB as measured by L1
  * `:rsrp` - Current RSRP in 1/10 dBm as measured by L1
  * `:rssi` - Current RSSI in 1/10 dBm as measured by L1
  * `:srxlev` - Cell selection Rx level (Srxlev) value (This field is only valid when
    ue_in_idle is TRUE.)
  """
  @type cell() :: %{
          pci: 0..503,
          rsrq: -200..-30,
          rsrp: -1400..-440,
          rssi: -1200..0,
          srxlev: -128..128
        }

  @typedoc """
  LTE Info - Intrafrequency

  * `:ue_in_idle` - true if the UE is in Idle mode
  * `:plmn` - coded as octet 3, 4, and 5 in 3GPP TS 24.008Section 10.5.1.3
  * `:tac` - Tracking area code
  * `:global_cell_id` - Global cell ID in the system information block
  * `:earfcn` - E-UTRA absolute radio frequency channel number of the serving cell.
  * `:serving_cell_id` - LTE serving cell ID. Range: 0 to 503. This is the cell ID
    of the serving cell and can be found in the cell list.
  * `:cell_resel_priority` - Priority for serving frequency. Range: 0 to 7. (This field
    is only valid when ue_in_idle is TRUE.)
  * `:s_non_intra_search` - S non-intra search threshold to control non-intrafrequency searches.
    Range: 0 to 31. (This field is only valid when ue_in_idle is
    TRUE.)
  * `:thresh_serving_low` - Serving cell low threshold. Range: 0 to 31. (This field is
    only valid when ue_in_idle is TRUE.)
  * `:s_intra_search` - S intra search threshold. Range: 0 to 31. The current cell measurement
    must fall below this threshold to consider intrafrequency for reselection.
    (This field is only valid when ue_in_idle is TRUE.)
  """
  @type lte_info_intrafrequency() :: %{
          ue_in_idle: boolean(),
          plmn: pos_integer(),
          tac: pos_integer(),
          global_cell_id: pos_integer(),
          earfcn: 0..65_535,
          serving_cell_id: 0..503,
          cell_resel_priority: 0..7,
          s_non_intra_search: 0..31,
          thresh_serving_low: 0..31,
          s_intra_search: 0..31,
          cells: [cell()]
        }

  @typedoc """
  Cell Location Info

  * `:timing_advance` - Timing advance of the LTE cell in microseconds
  * `:doppler_measurement` - Doppler measurement in Hz
  * `:lte_intra_earfcn` - LTE intrafrequency EARFCN extended size
  * `:lte_inter_earfcn` - LTE interfrequency EARFCN extended size
  """
  @type get_cell_location_info() :: %{
          optional(:lte_info_intrafrequency) => lte_info_intrafrequency(),
          optional(:timing_advance) => pos_integer(),
          optional(:doppler_measurement) => 0..400,
          optional(:lte_intra_earfcn) => pos_integer(),
          optional(:lte_inter_earfcn) => pos_integer()
        }

  @doc """
  Make the `QMI.request()` for getting cell location info
  """
  @spec get_cell_location_info() :: QMI.request()
  def get_cell_location_info() do
    %{
      service_id: @network_access_service_id,
      payload: <<@get_cell_location_info::little-16, 0x00::little-16>>,
      decode: &parse_get_cell_location_info/1
    }
  end

  defp parse_get_cell_location_info(
         <<@get_cell_location_info::little-16, _length::little-16, tlvs::binary>>
       ) do
    parse_get_cell_location_info_tlvs(%{}, tlvs)
  end

  defp parse_get_cell_location_info_tlvs(parsed, <<>>) do
    {:ok, parsed}
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x2, 0x04::little-16, _qmi_result::little-16, _qmi_error::little-16, rest::binary>>
       ) do
    parse_get_cell_location_info_tlvs(parsed, rest)
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x13, _length::little-16, ue_in_idle, plmn::3-bytes, tac::little-16,
           global_cell_id::little-32, earfcn::little-16, serving_cell_id::little-16,
           cell_resel_priority, s_non_intra_search, thresh_serving_low, s_intra_search, cells_len,
           cells_info::binary-size(cells_len * 10), rest::binary>>
       ) do
    lte_info_intrafrequency = %{
      ue_in_idle: ue_in_idle,
      plmn: plmn,
      tac: tac,
      global_cell_id: global_cell_id,
      earfcn: earfcn,
      serving_cell_id: serving_cell_id,
      cell_resel_priority: cell_resel_priority,
      s_non_intra_search: s_non_intra_search,
      thresh_serving_low: thresh_serving_low,
      s_intra_search: s_intra_search,
      cells: parse_cells([], cells_info)
    }

    parsed
    |> Map.put(:lte_info_intrafrequency, lte_info_intrafrequency)
    |> parse_get_cell_location_info_tlvs(rest)
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x14, length::little-16, _data::binary-size(length), rest::binary>>
       ) do
    # LTE Info - Interfrequency
    # Not sure how to decode this.
    parse_get_cell_location_info_tlvs(parsed, rest)
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x15, length::little-16, _data::binary-size(length), rest::binary>>
       ) do
    # LTE Info - Neighboring GSM
    # Not sure how to decode this.
    parse_get_cell_location_info_tlvs(parsed, rest)
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x16, length::little-16, _data::binary-size(length), rest::binary>>
       ) do
    # LTE Info - Neighboring WCDMA
    # Not sure how to decode this.
    parse_get_cell_location_info_tlvs(parsed, rest)
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x17, 4::little-16, umts_cell_id::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:umts_cell_id, umts_cell_id)
    |> parse_get_cell_location_info_tlvs(rest)
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x1E, 4::little-16, timing_advance::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:timing_advance, timing_advance)
    |> parse_get_cell_location_info_tlvs(rest)
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x26, 2::little-16, doppler_measurement::little-16, rest::binary>>
       ) do
    parsed
    |> Map.put(:doppler_measurement, doppler_measurement)
    |> parse_get_cell_location_info_tlvs(rest)
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x27, 4::little-16, lte_intra_earfcn::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:lte_intra_earfcn, lte_intra_earfcn)
    |> parse_get_cell_location_info_tlvs(rest)
  end

  defp parse_get_cell_location_info_tlvs(
         parsed,
         <<0x28, len::little-16, data::binary-size(len), rest::binary>>
       ) do
    <<lte_inter_earfcn_len, info::binary-size(lte_inter_earfcn_len * 4)>> = data
    lte_inter_earfcn = for <<x::little-32 <- info>>, do: x

    parsed
    |> Map.put(:lte_inter_earfcn, lte_inter_earfcn)
    |> parse_get_cell_location_info_tlvs(rest)
  end

  defp parse_cells(cells, <<>>), do: Enum.reverse(cells)

  defp parse_cells(
         cells,
         <<pci::little-16, rsrq::little-signed-16, rsrp::little-signed-16, rssi::little-signed-16,
           srxlev::little-signed-16, rest::binary>>
       ) do
    cell = %{pci: pci, rsrq: rsrq / 10, rsrp: rsrp / 10, rssi: rssi / 10, srxlev: srxlev}
    parse_cells([cell | cells], rest)
  end

  @typedoc """
  System table index referencing the beginning of
  the geo in which the current serving system is
  present. When the system index is not known,
  0xFFFF is used.
  """
  @type geo_sys_idx() :: 0..0xFFFF

  @typedoc """
  SIM rejection info

  * `:available` - SIM is available
  * `:not_available` - SIM is not available
  * `:cs_invalid` - SIM has been marked by the network as invalid for circuit-switched services
  * `:ps_invalid` - SIM has been marked by the network as invalid for packet-switched services
  * `:cs_ps_invalid` - SIM has been marked by the network as invalid for circuit-switched and
    packet-switched services
  """
  @type sim_rej_info() :: :not_available | :available | :cs_invalid | :ps_invalid | :cs_ps_invalid

  @typedoc """
  LTE Voice domain

  * `:no_voice` - No voice, stay on LTE
  * `:ims` - Voice is supported over the IMS network
  * `:"1X" - Voice is supported over the 1X network
  * `:"3GPP" - Voice is supported over the 3GPP network
  """
  @type lte_voice_status() :: :no_voice | :ims | :"1X" | :"3GPP"

  @typedoc """
  Registration restriction

  * `:unrestricted` - Device follows the normal registration process
  * `:camped_only` - Device follows the camp-only registration process
  """
  @type srv_reg_restriction() :: :unrestricted | :camped_only

  @typedoc """
  LTE registration domain

  * `:not_applicable` - UE is not in Camp Only mode
  * `:cs_only` - UE is in Camp Only mode and the PLMN can provide CS service only
  * `:ps_only` - UE is in Camp Only mode and the PLMN can provide PS service only
  * `:cs_ps` - UE is in Camp Only mode and the PLMN can provide CS and PS service
  * `:limited_service` - UE is in Camp Only mode, but the PLMN cannot provide any service
  """
  @type lte_reg_domain() :: :not_applicable | :cs_only | :ps_only | :cs_ps | :limited_service

  @typedoc """
  LTE SMS domain

  * `:no_sms` - No SMS, stay on LTE
  * `:ims` - SMS is supported over the IMS network
  * `:"1X" - SMS is supported over the 1X network
  * `:"3GPP" - SMS is supported over the 3GPP network
  """
  @type lte_sms_status() :: :no_sms | :ims | :"1X" | :"3GPP"

  @typedoc """
  Whether LTE emergency bearer is supported.

  * :true - LTE emergency bearer is supported
  * :false - LTE emergency bearer is NOT supported
  * :unknown - for scenarios where information is not available from the lower
    layers; e.g., if the UE powers up while acquiring service or in the middle
    of an attach procedure.
  """
  @type emergency_access() :: boolean() | :unknown

  @typedoc """
  Cell access status for LTE calls

  * `:normal_only` - Cell access is allowed for normal calls only
  * `:emergency_only` - Cell access is allowed for emergency calls only
  * `:no_calls` - Cell access is not allowed for any call type
  * `:all_calls` - Cell access is allowed for all call types
  * `:unknown` - Cell access type is unknown
  """
  @type lte_cell_status() :: :normal_only | :emergency_only | :no_calls | :all_calls | :unknown

  @typedoc """
  eMBMS coverage status

  * `:not_available` - Coverage not available
  * `:available` - Coverage available
  * `:not_available_due_to_uemode` - Coverage not available due to UE Mode
  * `:not_available_due_to_emergency` - Coverage not available due to emergency
  * `:unknown` - Coverage unknown
  """
  @type embms_coverage_status() ::
          :not_available
          | :available
          | :not_available_due_to_uemode
          | :not_available_due_to_emergency
          | :unknown

  @typedoc """
  LTE System Infox

  * `:srv_domain` - Service domain registered on the system
  * `:srv_capability` - Current system’s service capability
  * `:roam_status` - Current system's roaming status
  * `:is_sys_forbidden` - Whether the system is forbidden
  * `:lac` - Location area code (only applicable for 3GPP)
  * `:cell_id` - Cell ID
  * `:reg_reject_srv_domain` - Type of service domain in which the registration is rejected
  * `:reg_reject_cause` - Reject cause
  * `:mcc`, `:mnc` - ASCII network ID
  * `:tac` - Tracking area code (only applicable for LTE)
  """
  @type lte_sys_info() :: %{
          optional(:srv_domain) => :no_service | :cs_only | :ps_only | :cs_ps | :camped,
          optional(:srv_capability) => :no_service | :cs_only | :ps_only | :cs_ps | :camped,
          optional(:roam_status) =>
            :off
            | :on
            | :blink
            | :out_of_neighborhood
            | :out_of_building
            | :preferred_system
            | :available_system
            | :alliance_partner
            | :premium_partner
            | :full_service
            | :partial_service
            | :banner_on,
          optional(:is_sys_forbidden) => boolean(),
          optional(:lac) => pos_integer(),
          optional(:cell_id) => pos_integer(),
          optional(:reg_reject_srv_domain) =>
            :no_service | :cs_only | :ps_only | :cs_ps | :camped,
          optional(:reg_reject_cause) => pos_integer(),
          optional(:mcc) => String.t(),
          optional(:mnc) => String.t(),
          optional(:tac) => pos_integer()
        }

  @typedoc """
  Sys Info
  """
  @type get_sys_info() :: %{
          optional(:lte_sys_info) => lte_sys_info(),
          optional(:geo_sys_idx) => geo_sys_idx(),
          optional(:voice_support_on_lte) => boolean(),
          optional(:sim_rej_info) => sim_rej_info(),
          optional(:lte_ims_voice_avail) => boolean(),
          optional(:lte_voice_status) => lte_voice_status(),
          optional(:srv_reg_restriction) => srv_reg_restriction(),
          optional(:lte_reg_domain) => lte_reg_domain(),
          optional(:lte_embms_coverage_trace_id) => -1..32_768,
          optional(:lte_sms_status) => lte_sms_status(),
          optional(:lte_is_eb_supported) => emergency_access(),
          optional(:emergency_access_barred) => emergency_access(),
          optional(:lte_cell_status) => lte_cell_status(),
          optional(:embms_coverage_status) => embms_coverage_status()
        }

  @doc """
  Make the `QMI.request()` for getting cell location info
  """
  @spec get_sys_info() :: QMI.request()
  def get_sys_info() do
    %{
      service_id: @network_access_service_id,
      payload: <<@get_sys_info::little-16, 0x00::little-16>>,
      decode: &parse_get_sys_info/1
    }
  end

  defp parse_get_sys_info(<<@get_sys_info::little-16, _length::little-16, tlvs::binary>>) do
    parse_get_sys_info_tlvs(%{}, tlvs)
  end

  defp parse_get_sys_info_tlvs(parsed, <<>>) do
    {:ok, parsed}
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x2, 0x04::little-16, _qmi_result::little-16, _qmi_error::little-16, rest::binary>>
       ) do
    parse_get_sys_info_tlvs(parsed, rest)
  end

  defp parse_get_sys_info_tlvs(parsed, <<0x13, 0x03::little-16, _data::3-bytes, rest::binary>>) do
    parse_get_sys_info_tlvs(parsed, rest)
  end

  defp parse_get_sys_info_tlvs(parsed, <<0x14, 0x03::little-16, _data::3-bytes, rest::binary>>) do
    parse_get_sys_info_tlvs(parsed, rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x19, 29::little-16, lte_sys_info::29-bytes, rest::binary>>
       ) do
    parsed
    |> Map.put(:lte_sys_info, parse_lte_sys_info(lte_sys_info))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x1E, 2::little-16, geo_sys_idx::little-16, rest::binary>>
       ) do
    parsed
    |> Map.put(:geo_sys_idx, geo_sys_idx)
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x21, 1::little-16, voice_support_on_lte, rest::binary>>
       ) do
    parsed
    |> Map.put(:voice_support_on_lte, parse_voice_support_on_lte(voice_support_on_lte))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(parsed, <<0x26, 1::little-16, _deprecated, rest::binary>>) do
    parse_get_sys_info_tlvs(parsed, rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x27, 4::little-16, sim_rej_info::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:sim_rej_info, parse_sim_rej_info(sim_rej_info))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x29, 1::little-16, lte_ims_voice_avail, rest::binary>>
       ) do
    parsed
    |> Map.put(:lte_ims_voice_avail, parse_lte_ims_voice_avail(lte_ims_voice_avail))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x2A, 4::little-16, lte_voice_status::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:lte_voice_status, parse_lte_voice_status(lte_voice_status))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x2F, 4::little-16, srv_reg_restriction::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:srv_reg_restriction, parse_srv_reg_restriction(srv_reg_restriction))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x31, 4::little-16, lte_reg_domain::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:lte_reg_domain, parse_lte_reg_domain(lte_reg_domain))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x34, 2::little-16, lte_embms_coverage_trace_id::little-signed-16, rest::binary>>
       ) do
    parsed
    |> Map.put(:lte_embms_coverage_trace_id, lte_embms_coverage_trace_id)
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x38, 4::little-16, lte_sms_status::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:lte_sms_status, parse_lte_sms_status(lte_sms_status))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x39, 4::little-16, lte_is_eb_supported::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:lte_is_eb_supported, parse_lte_is_eb_supported(lte_is_eb_supported))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x3E, 4::little-16, emergency_access_barred::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:emergency_access_barred, parse_emergency_access_barred(emergency_access_barred))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x44, 4::little-16, lte_cell_status::little-signed-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:lte_cell_status, parse_lte_cell_status(lte_cell_status))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<0x46, 4::little-16, embms_coverage_status::little-32, rest::binary>>
       ) do
    parsed
    |> Map.put(:embms_coverage_status, parse_embms_coverage_status(embms_coverage_status))
    |> parse_get_sys_info_tlvs(rest)
  end

  defp parse_get_sys_info_tlvs(
         parsed,
         <<type, length::little-16, data::binary-size(length), rest::binary>>
       ) do
    Logger.debug(
      "[QMI]: Ignoring TLV from operator get_sys_info #{type} #{length} #{inspect(data)}"
    )

    parse_get_sys_info_tlvs(parsed, rest)
  end

  defp parse_lte_sys_info(
         <<srv_domain_valid, srv_domain, srv_capability_valid, srv_capability, roam_status_valid,
           roam_status, is_sys_forbidden_valid, is_sys_forbidden, lac_valid, lac::little-16,
           cell_id_valid, cell_id::little-32, reg_reject_info_valid, reject_srcv_domain,
           rej_cause, network_id_valid, mcc::3-bytes, mnc::3-bytes, tac_valid, tac::little-16>>
       ) do
    Enum.reduce(
      [
        {:srv_domain, srv_domain_valid, parse_srv_domain(srv_domain)},
        {:srv_capability, srv_capability_valid, parse_srv_capability(srv_capability)},
        {:roam_status, roam_status_valid, parse_roam_status(roam_status)},
        {:is_sys_forbidden, is_sys_forbidden_valid, parse_is_sys_forbidden(is_sys_forbidden)},
        {:lac, lac_valid, lac},
        {:cell_id, cell_id_valid, cell_id},
        {:reg_reject_srv_domain, reg_reject_info_valid,
         parse_reject_srcv_domain(reject_srcv_domain)},
        {:reg_reject_cause, reg_reject_info_valid, rej_cause},
        {:mcc, network_id_valid, trim_ascii_bytes(mcc)},
        {:mnc, network_id_valid, trim_ascii_bytes(mnc)},
        {:tac, tac_valid, tac}
      ],
      %{},
      fn {name, valid, value}, acc ->
        if valid == 1, do: Map.put(acc, name, value), else: acc
      end
    )
  end

  defp parse_srv_domain(0), do: :no_service
  defp parse_srv_domain(1), do: :cs_only
  defp parse_srv_domain(2), do: :ps_only
  defp parse_srv_domain(3), do: :cs_ps
  defp parse_srv_domain(4), do: :camped

  defp parse_srv_capability(0), do: :no_service
  defp parse_srv_capability(1), do: :cs_only
  defp parse_srv_capability(2), do: :ps_only
  defp parse_srv_capability(3), do: :cs_ps
  defp parse_srv_capability(4), do: :camped

  defp parse_roam_status(0), do: :off
  defp parse_roam_status(1), do: :on
  defp parse_roam_status(2), do: :blink
  defp parse_roam_status(3), do: :out_of_neighborhood
  defp parse_roam_status(4), do: :out_of_building
  defp parse_roam_status(5), do: :preferred_system
  defp parse_roam_status(6), do: :available_system
  defp parse_roam_status(7), do: :alliance_partner
  defp parse_roam_status(8), do: :premium_partner
  defp parse_roam_status(9), do: :full_service
  defp parse_roam_status(0x0A), do: :partial_service
  defp parse_roam_status(0x0B), do: :banner_on
  defp parse_roam_status(unknown), do: unknown

  defp parse_is_sys_forbidden(0), do: false
  defp parse_is_sys_forbidden(1), do: true

  defp parse_reject_srcv_domain(0), do: :no_service
  defp parse_reject_srcv_domain(1), do: :cs_only
  defp parse_reject_srcv_domain(2), do: :ps_only
  defp parse_reject_srcv_domain(3), do: :cs_ps
  defp parse_reject_srcv_domain(4), do: :camped

  defp parse_voice_support_on_lte(0), do: false
  defp parse_voice_support_on_lte(1), do: true

  defp parse_sim_rej_info(0), do: :not_available
  defp parse_sim_rej_info(1), do: :available
  defp parse_sim_rej_info(2), do: :cs_invalid
  defp parse_sim_rej_info(3), do: :ps_invalid
  defp parse_sim_rej_info(4), do: :cs_ps_invalid

  defp parse_lte_ims_voice_avail(0), do: false
  defp parse_lte_ims_voice_avail(1), do: true

  defp parse_lte_voice_status(0), do: :no_voice
  defp parse_lte_voice_status(1), do: :ims
  defp parse_lte_voice_status(2), do: :"1X"
  defp parse_lte_voice_status(3), do: :"3GPP"

  defp parse_srv_reg_restriction(0), do: :unrestricted
  defp parse_srv_reg_restriction(1), do: :camped_only

  defp parse_lte_reg_domain(0), do: :not_applicable
  defp parse_lte_reg_domain(1), do: :cs_only
  defp parse_lte_reg_domain(2), do: :ps_only
  defp parse_lte_reg_domain(3), do: :cs_ps
  defp parse_lte_reg_domain(4), do: :limited_service

  defp parse_lte_sms_status(0), do: :no_sms
  defp parse_lte_sms_status(1), do: :ims
  defp parse_lte_sms_status(2), do: :"1X"
  defp parse_lte_sms_status(3), do: :"3GPP"

  defp parse_lte_is_eb_supported(0), do: false
  defp parse_lte_is_eb_supported(1), do: true
  defp parse_lte_is_eb_supported(2), do: :unknown

  defp parse_emergency_access_barred(0), do: false
  defp parse_emergency_access_barred(1), do: true
  defp parse_emergency_access_barred(2), do: :unknown

  defp parse_lte_cell_status(0), do: :normal_only
  defp parse_lte_cell_status(1), do: :emergency_access_only
  defp parse_lte_cell_status(2), do: :no_calls
  defp parse_lte_cell_status(3), do: :all_calls
  defp parse_lte_cell_status(-1), do: :unknown

  defp parse_embms_coverage_status(0), do: :not_available
  defp parse_embms_coverage_status(1), do: :available
  defp parse_embms_coverage_status(2), do: :not_available_due_to_uemode
  defp parse_embms_coverage_status(3), do: :not_available_due_to_emergency
  defp parse_embms_coverage_status(4), do: :unknown

  @typedoc """
  The roaming preference

  * `:off` - acquire only systems for which the roaming indicator is off
  * `:not_off` - acquire a system as long as its roaming indicator is not off
  * `:not_flashing` - acquire a system as for which the roaming indicator is
    off or solid on - CDMA only.
  * `:any` - acquire systems, regardless of their roaming indicator
  """
  @type roaming_preference() :: :off | :not_off | :not_flashing | :any

  @typedoc """
  The networking selection preference

  * `:automatic` - automatically select the network
  * `:manual` - manually select the network
  """
  @type network_selection_preference() :: :automatic | :manual

  @typedoc """
  The network registration restriction preference

  * `:unrestricted` - device follows the normal registration process
  * `:camped_only` - device will camp on a network but not register
  * `:limited` - device selects the network for limited service

  This can also be integer value that is specified by the specific modem
  provider
  """
  @type registration_restriction_preference() ::
          :unrestricted | :camped_only | :limited | non_neg_integer()

  @typedoc """
  The modem usage preference setting

  `:unknown` - device does not know the usage preference setting
  `:voice_centric` - the device is set for voice centric usage
  `:data_centric` - the device is set for data centric
  """
  @type usage_setting_preference() :: :unknown | :voice_centric | :data_centric

  @typedoc """
  The voice domain preference setting

  * `:cs_only` - circuit-switched (CS) voice only
  * `:ps_only` - packet-switched (PS) voice only
  * `:cs_preferred` - PS is secondary
  * `:ps_preferred` - CS is secondary
  """
  @type voice_domain_preference() :: :cs_only | :ps_only | :cs_preferred | :ps_preferred

  @typedoc """
  Preference settings for when a device selects a system

  * `:emergency_mode` - `:on` if the device is in emergency mode, `:off`
    otherwise
  * `:mode_preference` - a list of radio access technologies the device will
    try to use
  * `:roaming_preference` - the device roaming preference
  * `:network_selection_preference` - if the device will automatically select
    a network
  * `:acquisition_order` - the order in which the device will try to connect
    to a radio access technology
  * `:registration_restriction` - the system registration restriction
  * `:usage_settings` - the modem usage preference
  * `:voice_domain_preference` - the voice domain preference
  """
  @type get_system_selection_preference_response() :: %{
          optional(:emergency_mode) => :off | :on,
          optional(:mode_preference) => [radio_interface()],
          optional(:roaming_preference) => roaming_preference(),
          optional(:network_selection_preference) => network_selection_preference(),
          optional(:acquisition_order) => [radio_interface()],
          optional(:registration_restriction) => registration_restriction_preference(),
          optional(:usage_settings) => usage_setting_preference(),
          optional(:voice_domain) => voice_domain_preference()
        }

  @doc """
  Make `QMI.request()` to get the system selection preferences
  """
  @spec get_system_selection_preference() :: QMI.request()
  def get_system_selection_preference() do
    %{
      service_id: @network_access_service_id,
      payload: <<@get_system_selection_preference::little-16, 0x00, 0x00>>,
      decode: &parse_get_system_selection_preference/1
    }
  end

  defp parse_get_system_selection_preference(
         <<@get_system_selection_preference::little-16, size::little-16, tlvs::binary-size(size)>>
       ) do
    {:ok, do_parse_get_system_selection_preference(%{}, tlvs)}
  end

  defp parse_get_system_selection_preference(_other) do
    {:error, :unexpected_response}
  end

  defp do_parse_get_system_selection_preference(parsed_tlvs, <<>>) do
    parsed_tlvs
  end

  defp do_parse_get_system_selection_preference(
         tlvs,
         <<0x10, 0x01::little-16, emergency_mode, rest::binary>>
       ) do
    tlvs
    |> Map.put(:emergency_mode, parse_emergency_mode(emergency_mode))
    |> do_parse_get_system_selection_preference(rest)
  end

  defp do_parse_get_system_selection_preference(
         tlvs,
         <<0x11, 0x02::little-16, rat_mask::little-16, rest::binary>>
       ) do
    possible_rats = [
      {:cdma_1x, 0x01},
      {:cdma_1x_evdo, 0x02},
      {:gsm, 0x04},
      {:umts, 0x08},
      {:lte, 0x10},
      {:td_scdma, 0x20}
    ]

    rats_list =
      Enum.reduce(possible_rats, [], fn {rat, byte}, list ->
        if (rat_mask &&& byte) == byte do
          [rat | list]
        else
          list
        end
      end)

    tlvs
    |> Map.put(:mode_preference, rats_list)
    |> do_parse_get_system_selection_preference(rest)
  end

  defp do_parse_get_system_selection_preference(
         tlvs,
         <<0x14, 0x02::little-16, roam_pref::little-16, rest::binary>>
       ) do
    tlvs
    |> Map.put(:roaming_preference, parse_roaming_preference(roam_pref))
    |> do_parse_get_system_selection_preference(rest)
  end

  defp do_parse_get_system_selection_preference(
         tlvs,
         <<0x16, 0x01::little-16, network_selection_pref, rest::binary>>
       ) do
    tlvs
    |> Map.put(
      :network_selection_preference,
      parse_network_selection_preference(network_selection_pref)
    )
    |> do_parse_get_system_selection_preference(rest)
  end

  defp do_parse_get_system_selection_preference(
         tlvs,
         <<0x1C, _size::16, number_or_rats, rat_acquisition_order::binary-size(number_or_rats),
           rest::binary>>
       ) do
    rat_acquisition_order_list =
      rat_acquisition_order |> :erlang.binary_to_list() |> Enum.map(&radio_interface/1)

    tlvs
    |> Map.put(:acquisition_order, rat_acquisition_order_list)
    |> do_parse_get_system_selection_preference(rest)
  end

  defp do_parse_get_system_selection_preference(
         tlvs,
         <<0x1D, 0x04::little-16, registration_restriction::little-32, rest::binary>>
       ) do
    tlvs
    |> Map.put(
      :registration_restriction,
      parse_registration_restriction(registration_restriction)
    )
    |> do_parse_get_system_selection_preference(rest)
  end

  defp do_parse_get_system_selection_preference(
         tlvs,
         <<0x1F, 0x04::little-16, setting::little-32, rest::binary>>
       ) do
    tlvs
    |> Map.put(:usage_setting, parse_usage_setting(setting))
    |> do_parse_get_system_selection_preference(rest)
  end

  defp do_parse_get_system_selection_preference(
         tlvs,
         <<0x20, 0x04::little-16, domain_pref::little-32, rest::binary>>
       ) do
    tlvs
    |> Map.put(:void_domain_preference, parse_voice_domain_preference(domain_pref))
    |> do_parse_get_system_selection_preference(rest)
  end

  defp do_parse_get_system_selection_preference(
         tlvs,
         <<_type, size::little-16, _tlvs::binary-size(size), rest::binary>>
       ) do
    do_parse_get_system_selection_preference(tlvs, rest)
  end

  defp parse_registration_restriction(0x00), do: :unrestricted
  defp parse_registration_restriction(0x01), do: :camped_only
  defp parse_registration_restriction(0x02), do: :limited
  defp parse_registration_restriction(byte), do: byte

  defp parse_usage_setting(0), do: :unknown
  defp parse_usage_setting(1), do: :voice_centric
  defp parse_usage_setting(2), do: :data_centric

  defp parse_voice_domain_preference(0x00), do: :cs_only
  defp parse_voice_domain_preference(0x01), do: :ps_only
  defp parse_voice_domain_preference(0x02), do: :cs_preferred
  defp parse_voice_domain_preference(0x03), do: :ps_preferred

  defp parse_emergency_mode(0x00), do: :off
  defp parse_emergency_mode(0x01), do: :on

  defp parse_roaming_preference(0x01), do: :off
  defp parse_roaming_preference(0x02), do: :not_off
  defp parse_roaming_preference(0x03), do: :not_flashing
  defp parse_roaming_preference(0xFF), do: :any

  defp parse_network_selection_preference(0x00), do: :automatic
  defp parse_network_selection_preference(0x01), do: :manual

  @doc """
  Generate the `QMI.request()` for setting system selection preferences
  """
  @spec set_system_selection_preference([set_system_selection_preference_opt()]) :: QMI.request()
  def set_system_selection_preference(opts \\ []) do
    {tlvs, size} = make_tlvs(opts)
    payload = [<<@set_system_selection_preference::little-16, size::little-16>>, tlvs]

    %{
      service_id: @network_access_service_id,
      payload: payload,
      decode: &parse_set_system_selection_preference/1
    }
  end

  defp make_tlvs(opts) do
    opts = Keyword.put_new(opts, :change_duration, :permanent)

    do_make_tlvs(opts, [], 0)
  end

  defp do_make_tlvs([], tlvs, bytes), do: {tlvs, bytes}

  defp do_make_tlvs([{:change_duration, :permanent} | rest], tlvs, bytes) do
    tlv = <<0x17, 0x01::little-16, 0x01>>

    do_make_tlvs(rest, tlvs ++ [tlv], bytes + 4)
  end

  defp do_make_tlvs([{:change_duration, :power_cycle} | rest], tlvs, bytes) do
    tlv = <<0x17, 0x01::little-16, 0x00>>

    do_make_tlvs(rest, tlvs ++ [tlv], bytes + 4)
  end

  defp do_make_tlvs([{:mode_preference, radio_techs} | rest], tlvs, bytes) do
    radio_techs_mask =
      Enum.reduce(radio_techs, 0x00, fn
        :cdma_1x, mask -> mask ||| 0x01
        :cdma_1x_hrdp, mask -> mask ||| 0x02
        :gsm, mask -> mask ||| 0x04
        :umts, mask -> mask ||| 0x08
        :lte, mask -> mask ||| 0x10
        :td_scdma, mask -> mask ||| 0x20
        _other, mask -> mask
      end)

    tlv = <<0x11, 0x02::little-16, radio_techs_mask::little-16>>

    do_make_tlvs(rest, tlvs ++ [tlv], bytes + 5)
  end

  defp do_make_tlvs([{:roaming_preference, roaming_preference} | rest], tlvs, bytes) do
    roaming_byte = encode_roaming_preference(roaming_preference)

    tlv = <<0x14, 0x02::little-16, roaming_byte::little-16>>
    do_make_tlvs(rest, tlvs ++ [tlv], bytes + 5)
  end

  defp encode_roaming_preference(:off), do: 0x01
  defp encode_roaming_preference(:not_off), do: 0x02
  defp encode_roaming_preference(:not_flashing), do: 0x03
  defp encode_roaming_preference(:any), do: 0xFF

  defp parse_set_system_selection_preference(
         <<@set_system_selection_preference::little-16, _rest::binary>>
       ) do
    :ok
  end

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
         <<@get_home_network::little-16, size::little-16, tlvs::binary-size(size)>>
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
         <<0x01, size::little-16, values::binary-size(size), rest::binary>>
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
         <<_type, length::little-16, _values::binary-size(length), rest::binary>>
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
        <<@serving_system_indication::little-16, size::little-16, tlvs::binary-size(size)>>
      ) do
    result =
      :serving_system_indication
      |> init_indication()
      |> parse_serving_system_indication(tlvs)

    {:ok, result}
  end

  def parse_indication(
        <<@operator_name_indication::little-16, size::little-16, tlvs::binary-size(size)>>
      ) do
    result =
      :operator_name_indication
      |> init_indication()
      |> parse_operator_name_indication(tlvs)

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

  defp init_indication(:operator_name_indication = name) do
    %{
      name: name,
      long_name: "",
      short_name: ""
    }
  end

  defp parse_operator_name_indication(indication, <<>>), do: indication

  defp parse_operator_name_indication(
         indication,
         <<0x14, size::little-16, nitz_info::binary-size(size), rest::binary>>
       ) do
    <<name_encoding, _other_encodings::24, long_name_size, long_name::binary-size(long_name_size),
      short_name_size, short_name::binary-size(short_name_size)>> = nitz_info

    indication
    |> Map.put(:long_name, parse_operator_name(name_encoding, long_name))
    |> Map.put(:short_name, parse_operator_name(name_encoding, short_name))
    |> parse_operator_name_indication(rest)
  end

  defp parse_operator_name_indication(
         indication,
         <<type, size, values::binary-size(size), rest::binary>>
       ) do
    Logger.debug("[QMI]: Ignoring TLV from operator name indication #{type} #{size} #{values}")

    parse_operator_name(indication, rest)
  end

  # libQMI parses UCS2 as UTF-16.
  # https://gitlab.freedesktop.org/mobile-broadband/libqmi/-/blob/master/src/libqmi-glib/qmi-helpers.c#L404
  defp parse_operator_name(1, name), do: :unicode.characters_to_binary(name, {:utf16, :big})
  defp parse_operator_name(_other_encoding, name), do: name

  defp parse_serving_system_indication(parsed, <<>>) do
    parsed
  end

  defp parse_serving_system_indication(
         parsed,
         <<0x01, length::little-16, values::binary-size(length), rest::binary>>
       ) do
    <<registration_state, cs_attach_state, ps_attach_state, selected_network, num_radio_if,
      radio_if::binary-size(num_radio_if)>> = values

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
    indication = try_parse_std_offset(serving_system_indication, rest)

    indication
    |> Map.put(:utc_offset, calc_utc_offset(indication, offset))
    |> parse_serving_system_indication(rest)
  end

  defp parse_serving_system_indication(
         %{std_offset: _std_offset} = indication,
         <<0x1B, 0x01::little-16, _adjustment, rest::binary>>
       ) do
    parse_serving_system_indication(indication, rest)
  end

  defp parse_serving_system_indication(
         serving_system_indication,
         <<0x1B, 0x01::little-16, adjustment, rest::binary>>
       ) do
    serving_system_indication
    |> Map.put(:std_offset, adjustment * 3600)
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
    indication = try_parse_std_offset(serving_system_indication, rest)
    {:ok, datetime} = NaiveDateTime.new(year, month, day, hour, minute, second)

    indication
    |> Map.put(:network_datetime, datetime)
    |> Map.put(:utc_offset, calc_utc_offset(indication, tz_offset))
    |> parse_serving_system_indication(rest)
  end

  defp parse_serving_system_indication(
         parsed,
         <<_type, length::little-16, _values::binary-size(length), rest::binary>>
       ) do
    parse_serving_system_indication(parsed, rest)
  end

  defp try_parse_std_offset(%{std_offset: _std_offset} = indication, _binary) do
    indication
  end

  defp try_parse_std_offset(indication, <<>>) do
    indication
  end

  defp try_parse_std_offset(indication, <<0x1B, 0x01::little-16, adjustment, _rest::binary>>) do
    indication
    |> Map.put(:std_offset, adjustment * 3600)
  end

  defp try_parse_std_offset(
         indication,
         <<_type, length::little-16, _values::binary-size(length), rest::binary>>
       ) do
    try_parse_std_offset(indication, rest)
  end

  defp serving_system_registration_state(0x00), do: :not_registered
  defp serving_system_registration_state(0x01), do: :registered
  defp serving_system_registration_state(0x02), do: :not_registered_searching
  defp serving_system_registration_state(0x03), do: :registration_denied
  defp serving_system_registration_state(0x04), do: :registration_unknown

  defp serving_system_attach_state(0x00), do: :unknown
  defp serving_system_attach_state(0x01), do: :attached
  defp serving_system_attach_state(0x02), do: :detached

  defp serving_system_network(0x00), do: :network_unknown
  defp serving_system_network(0x01), do: :network_3gpp2
  defp serving_system_network(0x02), do: :network_3gpp

  defp calc_utc_offset(%{std_offset: std_offset}, tz_offset) do
    # QMI reports the overall offset. Elixir splits the offset into the amount
    # that goes to standard time (utc_offset) + the daylight savings offset
    # from standard time (std_offset).
    utc_offset_to_seconds(tz_offset) - std_offset
  end

  defp calc_utc_offset(_indication, tz_offset) do
    utc_offset_to_seconds(tz_offset)
  end

  defp utc_offset_to_seconds(offset), do: offset * 15 * 60

  @doc """
  Get the radio band information
  """
  @spec get_rf_band_info() :: QMI.request()
  def get_rf_band_info() do
    %{
      service_id: @network_access_service_id,
      payload: <<@get_rf_band_info::little-16, 0x00::little-16>>,
      decode: &parse_get_rf_band_info_resp/1
    }
  end

  defp parse_get_rf_band_info_resp(
         <<@get_rf_band_info::little-16, length::little-16, values::binary-size(length)>>
       ) do
    result = parse_get_rf_band_values([], values)

    {:ok, result}
  end

  defp parse_get_rf_band_info_resp(_binary) do
    {:error, :unexpected_response}
  end

  defp parse_get_rf_band_values(rf_band_info_list, <<>>) do
    rf_band_info_list
  end

  defp parse_get_rf_band_values(
         rf_band_info_list,
         <<0x01, length::little-16, radio_band_information::binary-size(length), rest::binary>>
       ) do
    rf_band_info_list
    |> parse_radio_ifs(radio_band_information)
    |> parse_get_rf_band_values(rest)
  end

  defp parse_get_rf_band_values(
         rf_band_info_list,
         <<_type, length::little-16, _values::binary-size(length), rest::binary>>
       ) do
    parse_get_rf_band_values(rf_band_info_list, rest)
  end

  defp parse_radio_ifs(rf_band_info_list, <<number_of_instances, radio_ifs_bin::binary>>) do
    parse_radio_band_information(rf_band_info_list, number_of_instances, radio_ifs_bin)
  end

  defp parse_radio_band_information(radio_ifs, 0, <<>>) do
    radio_ifs
  end

  defp parse_radio_band_information(
         radio_ifs,
         n,
         <<radio_if, active_band::little-16, active_channel::little-16, rest::binary>>
       ) do
    rifs =
      radio_ifs ++
        [
          %{
            interface: radio_interface(radio_if),
            band: parse_active_band(active_band),
            channel: active_channel
          }
        ]

    parse_radio_band_information(rifs, n - 1, rest)
  end

  # Parsing logic uses libqmi enumeration definition as reference
  # https://gitlab.freedesktop.org/mobile-broadband/libqmi/-/blob/master/src/libqmi-glib/qmi-enums-nas.h#L173-269
  defp parse_active_band(band) when band >= 0 and band <= 19 do
    "CDMA Band Class #{band}"
  end

  defp parse_active_band(band) when band >= 40 and band <= 48 do
    "GSM #{gsm_band_name(band)}"
  end

  defp parse_active_band(band) when band >= 80 and band <= 91 and band != 89 do
    "WCDMA #{wcdma_band_name(band)}"
  end

  defp parse_active_band(band) when band >= 120 and band <= 162 do
    "LTE Band #{lte_band_name(band)}"
  end

  defp parse_active_band(band) when band >= 200 and band <= 205 do
    "TDS-CDMA Band #{tds_cdma_band_name(band)}"
  end

  defp parse_active_band(band) do
    "Unknown Band #{band}"
  end

  defp gsm_band_name(40), do: "450"
  defp gsm_band_name(41), do: "480"
  defp gsm_band_name(42), do: "750"
  defp gsm_band_name(43), do: "850"
  defp gsm_band_name(44), do: "900 Extended"
  defp gsm_band_name(45), do: "900 Primary"
  defp gsm_band_name(46), do: "900 Railways"
  defp gsm_band_name(47), do: "DCS 1800"
  defp gsm_band_name(48), do: "PCS 1900"

  defp wcdma_band_name(80), do: "2100"
  defp wcdma_band_name(81), do: "PCS 1900"
  defp wcdma_band_name(82), do: "DCS 1800"
  defp wcdma_band_name(83), do: "1700 US"
  defp wcdma_band_name(84), do: "850"
  defp wcdma_band_name(85), do: "800"
  defp wcdma_band_name(86), do: "2600"
  defp wcdma_band_name(87), do: "900"
  defp wcdma_band_name(88), do: "1700 Japan"
  defp wcdma_band_name(90), do: "1500 Japan"
  defp wcdma_band_name(91), do: "850 Japan"

  defp lte_band_name(n), do: Integer.to_string(n - 120 + 1)

  defp tds_cdma_band_name(200), do: "A"
  defp tds_cdma_band_name(201), do: "B"
  defp tds_cdma_band_name(202), do: "C"
  defp tds_cdma_band_name(203), do: "D"
  defp tds_cdma_band_name(204), do: "E"
  defp tds_cdma_band_name(205), do: "F"

  defp trim_ascii_bytes(value, acc \\ <<>>)

  defp trim_ascii_bytes(<<char, rest::binary>>, acc) do
    char_str = <<char>>
    # the specification doesn't provide an explicit termination
    # character, so check if it's printable to determine termination
    if String.printable?(char_str) do
      trim_ascii_bytes(rest, acc <> char_str)
    else
      acc
    end
  end

  defp trim_ascii_bytes(<<>>, acc), do: acc
end
