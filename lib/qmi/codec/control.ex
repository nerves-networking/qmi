defmodule QMI.Codec.Control do
  @moduledoc """
  Codec for making control service requests
  """

  @get_client_id 0x0022
  @release_client_id 0x0023

  @doc """
  Request for getting a client id
  """
  @spec get_client_id(QMI.Control.service_id()) :: QMI.request()
  def get_client_id(service_id) do
    %{
      payload: <<@get_client_id::little-16, 0x04::little-16, 0x01, 0x01::little-16, service_id>>,
      decode: &parse_get_client_id_response/1
    }
  end

  @doc """
  Release a client id
  """
  @spec release_client_id(QMI.Control.service_id(), QMI.Control.client_id()) :: QMI.request()
  def release_client_id(service_id, client_id) do
    %{
      payload:
        <<@release_client_id::little-16, 0x05::little-16, 0x01, 0x02::little-16, service_id,
          client_id>>,
      decode: &parse_release_client_id_response/1
    }
  end

  @doc """
  Parse the expected response from requesting a client id
  """
  @spec parse_get_client_id_response(binary()) :: map()
  def parse_get_client_id_response(
        <<@get_client_id::little-16, size::little-16, tlvs::size(size)-binary>>
      ) do
    parse_get_client_id_tlvs(%{}, tlvs)
  end

  defp parse_get_client_id_tlvs(parsed, <<>>) do
    parsed
  end

  defp parse_get_client_id_tlvs(
         parsed,
         <<0x01, 0x02::little-16, service_id, client_id, rest::binary>>
       ) do
    parsed
    |> Map.put(:service_id, service_id)
    |> Map.put(:client_id, client_id)
    |> parse_get_client_id_tlvs(rest)
  end

  defp parse_get_client_id_tlvs(
         parsed,
         <<_type, size::little-16, _values::size(size)-binary, rest::binary>>
       ) do
    parse_get_client_id_tlvs(parsed, rest)
  end

  @doc """
  Parse the expected response from releasing a client id
  """
  def parse_release_client_id_response(
        <<@release_client_id::little-16, size::little-16, values::size(size)-binary>>
      ) do
    parse_release_client_id_tlvs(%{}, values)
  end

  defp parse_release_client_id_tlvs(parsed, <<>>) do
    parsed
  end

  defp parse_release_client_id_tlvs(
         parsed,
         <<0x01, 0x02::little-16, service_id, client_id, rest::binary>>
       ) do
    parsed
    |> Map.put(:service_id, service_id)
    |> Map.put(:client_id, client_id)
    |> parse_release_client_id_tlvs(rest)
  end

  defp parse_release_client_id_tlvs(
         parsed,
         <<_type, size::little-16, _values::size(size)-binary, rest::binary>>
       ) do
    parse_release_client_id_tlvs(parsed, rest)
  end
end
