# SPDX-FileCopyrightText: 2021 Matt Ludwigs
# SPDX-FileCopyrightText: 2023 Liv Cella
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.Codec.UserIdentity do
  @moduledoc """
  Codec for making user identity service requests
  """

  @read_transparent 0x0020
  @get_card_status 0x002F
  @change_uim_session 0x0038

  @typedoc """
  The response from issuing a read transparent request
  """
  @type read_transparent_response() :: %{
          sw1_result_code: non_neg_integer() | nil,
          sw2_result_code: non_neg_integer() | nil,
          read_result: binary() | nil
        }

  @doc """
  Read any transparent file in the card and access by path
  """
  @spec read_transparent(non_neg_integer(), non_neg_integer()) :: QMI.request()
  def read_transparent(file_id, file_path) do
    session = session_tlv()
    file = file_id_tlv(file_id, file_path)
    read_info = read_info_tlv()
    tlvs = <<session::binary, file::binary, read_info::binary>>

    size = byte_size(tlvs)

    %{
      service_id: 0x0B,
      payload: [<<@read_transparent::little-16, size::little-16>>, tlvs],
      decode: &parse/1
    }
  end

  defp session_tlv() do
    <<0x01, 0x02, 0x00, 0x00, 0x00>>
  end

  defp file_id_tlv(file_id, file_path) do
    <<0x02, 0x05, 0x00, file_id::little-16, 0x02, file_path::little-16>>
  end

  defp read_info_tlv() do
    <<0x03, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00>>
  end

  defp parse(<<@read_transparent::little-16, size::little-16, tlvs::binary-size(size)>>) do
    %{sw1_result_code: nil, sw2_result_code: nil, read_result: nil}
    |> parse_tlvs(tlvs)
  end

  defp parse(_other) do
    {:error, :unexpected_response}
  end

  defp parse_tlvs(result, <<>>) do
    {:ok, result}
  end

  defp parse_tlvs(
         result,
         <<0x11, _size::little-16, content_len::little-16, bytes::binary-size(content_len),
           rest::binary>>
       ) do
    result
    |> Map.put(:read_result, bytes)
    |> parse_tlvs(rest)
  end

  defp parse_tlvs(result, <<0x10, 0x02::little-16, sw1_code, sw2_code, rest::binary>>) do
    result
    |> Map.put(:sw1_result_code, sw1_code)
    |> Map.put(:sw2_result_code, sw2_code)
    |> parse_tlvs(rest)
  end

  defp parse_tlvs(result, <<_type, size::little-16, _values::binary-size(size), rest::binary>>) do
    parse_tlvs(result, rest)
  end

  @doc """
  Provision a UIM session for a specific application.

  This creates a session context for communicating with a specific application
  on a particular card slot.
  """
  @spec provision_uim_session(non_neg_integer(), binary()) :: QMI.request()
  def provision_uim_session(slot_id, application_id) do
    application_information_tlv = application_information_tlv(slot_id, application_id)
    session_change_tlv = session_change_tlv()
    tlvs = <<application_information_tlv::binary, session_change_tlv::binary>>
    size = byte_size(tlvs)

    %{
      service_id: 0x0B,
      payload: [<<@change_uim_session::little-16, size::little-16>>, tlvs],
      decode: &parse_provisioning_response/1
    }
  end

  defp application_information_tlv(slot_id, application_id) do
    aid_len = byte_size(application_id)

    <<0x10, aid_len + 2::little-16, slot_id::8, aid_len::8, application_id::binary>>
  end

  # TLV 0x01: Session change
  # session_type = 0x00 (primary GW provisioning), activate = 0x01
  defp session_change_tlv() do
    <<0x01, 0x02::little-16, 0x00, 0x01>>
  end

  defp parse_provisioning_response(
         <<@change_uim_session::little-16, _tlv_length::little-16, 0x02, _value_length::little-16,
           0x00, 0x00, 0x00, 0x00>>
       ) do
    :ok
  end

  defp parse_provisioning_response(<<@change_uim_session::little-16, _rest::binary>>) do
    {:error, :provisioning_failed}
  end

  @doc """
  Get the status of all card slots in the device.

  This command retrieves information about all available card slots and their current state.
  """
  @spec get_cards_status() :: QMI.request()
  def get_cards_status() do
    %{
      service_id: 0x0B,
      payload: [<<@get_card_status::16-little, 0x00, 0x00>>],
      decode: &parse_card_status_response/1
    }
  end

  defp parse_card_status_response(
         <<@get_card_status::little-16, _length::little-16, tlvs::binary>>
       ) do
    result = %{
      index_gw_primary: nil,
      index_1x_primary: nil,
      index_gw_secondary: nil,
      index_1x_secondary: nil,
      cards: []
    }

    parse_card_status_tlvs(result, tlvs)
  end

  defp parse_card_status_tlvs(
         result,
         <<0x10, length::little-16, content::binary-size(length), tlvs::binary>>
       ) do
    parse_cards_tlv(result, content)
    |> parse_card_status_tlvs(tlvs)
  end

  defp parse_card_status_tlvs(result, <<0x10, length::little-16, content::binary-size(length)>>) do
    parse_cards_tlv(result, content)
  end

  defp parse_card_status_tlvs(
         result,
         <<_type, length::little-16, _content::binary-size(length), tlvs::binary>>
       ) do
    parse_card_status_tlvs(result, tlvs)
  end

  defp parse_card_status_tlvs(result, <<>>) do
    {:ok, result}
  end

  defp parse_cards_tlv(result, content) do
    <<index_gw_primary::little-16, index_1x_primary::little-16, index_gw_secondary::little-16,
      index_1x_secondary::little-16, cards_count::8, rest::binary>> = content

    result
    |> Map.put(:index_gw_primary, index_gw_primary)
    |> Map.put(:index_1x_primary, index_1x_primary)
    |> Map.put(:index_gw_secondary, index_gw_secondary)
    |> Map.put(:index_1x_secondary, index_1x_secondary)
    |> parse_cards(cards_count, rest, 1)
  end

  defp parse_cards(result, 0, _rest, _slot_id) do
    result
  end

  defp parse_cards(
         result,
         n,
         <<
           card_state::8,
           upin_state::8,
           upin_retries::8,
           upuk_retries::8,
           error_code::8,
           num_apps::8,
           rest::binary
         >>,
         slot_id
       ) do
    card = %{
      slot_id: slot_id,
      card_state: card_state,
      upin_state: upin_state,
      upin_retries: upin_retries,
      upuk_retries: upuk_retries,
      error_code: error_code,
      num_apps: num_apps
    }

    {applications, rest_after_apps} = parse_applications(rest, num_apps)
    updated_card = card |> Map.put(:applications, applications)
    updated_result = Map.update!(result, :cards, fn cards -> [updated_card | cards] end)
    parse_cards(updated_result, n - 1, rest_after_apps, slot_id + 1)
  end

  defp parse_applications(rest, num_apps) do
    parse_application([], num_apps, rest)
  end

  defp parse_application(result, 0, rest) do
    {Enum.reverse(result), rest}
  end

  defp parse_application(
         result,
         n,
         <<app_type::8, app_state::8, personalization_state::8, personalization_feature::8,
           personalization_retries::8, personalization_unblock_retries::8, aid_len::8,
           aid::binary-size(aid_len), upin_replaces_pin1::8, pin1_state::8, pin1_retries::8,
           puk1_retries::8, pin2_state::8, pin2_retries::8, puk2_retries::8,
           rest_after_app::binary>>
       ) do
    app = %{
      type: app_type,
      state: app_state,
      personalization_state: personalization_state,
      personalization_feature: personalization_feature,
      personalization_retries: personalization_retries,
      personalization_unblock_retries: personalization_unblock_retries,
      aid: aid,
      upin_replaces_pin1: upin_replaces_pin1,
      pin1_state: pin1_state,
      pin1_retries: pin1_retries,
      puk1_retries: puk1_retries,
      pin2_state: pin2_state,
      pin2_retries: pin2_retries,
      puk2_retries: puk2_retries
    }

    updated_result = [app | result]
    parse_application(updated_result, n - 1, rest_after_app)
  end
end
