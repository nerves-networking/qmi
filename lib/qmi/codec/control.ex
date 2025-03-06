# SPDX-FileCopyrightText: 2021 Matt Ludwigs
# SPDX-FileCopyrightText: 2023 Liv Cella
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.Codec.Control do
  @moduledoc """
  Codec for making control service requests
  """

  @get_client_id 0x0022
  @release_client_id 0x0023
  @sync_indication 0x0027

  @type sync_indication() :: %{
          name: :sync_indication
        }

  @doc """
  Request for getting a client id
  """
  @spec get_client_id(non_neg_integer()) :: QMI.request()
  def get_client_id(service_id) do
    %{
      service_id: 0x00,
      payload: <<@get_client_id::little-16, 0x04::little-16, 0x01, 0x01::little-16, service_id>>,
      decode: &parse_get_client_id_response/1
    }
  end

  defp parse_get_client_id_response(
         <<@get_client_id::little-16, size::little-16, tlvs::binary-size(size)>>
       ) do
    parse_get_client_id_tlvs(tlvs)
  end

  defp parse_get_client_id_response(_other) do
    {:error, :unexpected_response}
  end

  defp parse_get_client_id_tlvs(<<>>) do
    {:error, :unexpected_response}
  end

  defp parse_get_client_id_tlvs(<<0x01, 0x02::little-16, _service_id, client_id, _rest::binary>>) do
    {:ok, client_id}
  end

  defp parse_get_client_id_tlvs(
         <<_type, size::little-16, _values::binary-size(size), rest::binary>>
       ) do
    parse_get_client_id_tlvs(rest)
  end

  @doc """
  Release a client id
  """
  @spec release_client_id(non_neg_integer(), non_neg_integer()) :: QMI.request()
  def release_client_id(service_id, client_id) do
    %{
      service_id: 0x00,
      payload:
        <<@release_client_id::little-16, 0x05::little-16, 0x01, 0x02::little-16, service_id,
          client_id>>,
      decode: &parse_release_client_id_response(&1, service_id, client_id)
    }
  end

  defp parse_release_client_id_response(
         <<@release_client_id::little-16, size::little-16, values::binary-size(size)>>,
         expected_service_id,
         expected_client_id
       ) do
    case parse_release_client_id_tlvs(values) do
      {^expected_service_id, ^expected_client_id} -> :ok
      _ -> {:error, :unexpected_response}
    end
  end

  defp parse_release_client_id_tlvs(<<>>) do
    nil
  end

  defp parse_release_client_id_tlvs(
         <<0x01, 0x02::little-16, service_id, client_id, _rest::binary>>
       ) do
    {service_id, client_id}
  end

  defp parse_release_client_id_tlvs(
         <<_type, size::little-16, _values::binary-size(size), rest::binary>>
       ) do
    parse_release_client_id_tlvs(rest)
  end

  @doc """
  Parse indications for the the control service
  """
  @spec parse_indication(binary()) :: {:ok, sync_indication()} | {:error, :invalid_indication}
  def parse_indication(<<@sync_indication::little-16, 0x00, 0x00>>) do
    {:ok, %{name: :sync_indication}}
  end

  def parse_indication(_binary), do: {:error, :invalid_indication}
end
