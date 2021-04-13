defmodule QMI.Codec.Control do
  @moduledoc """
  Codec for making control service requests
  """

  @get_client_id 0x0022
  @release_client_id 0x0032

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
        <<@get_client_id::little-16, 0x05::little-16, 0x01, 0x02::little-16, service_id,
          client_id>>
      ) do
    %{service_id: service_id, client_id: client_id}
  end

  @doc """
  Parse the expected response from releasing a client id
  """
  def parse_release_client_id_response(
        <<@release_client_id::little-16, 0x05, 0x01, 0x02::little-16, service_id, client_id>>
      ) do
    %{service_id: service_id, client_id: client_id}
  end
end
