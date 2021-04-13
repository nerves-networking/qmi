defmodule QMI.Control do
  alias QMI.Codec

  @doc """
  Get a client id for a service
  """
  def get_client_id(control_point, service_id) do
    request = Codec.Control.get_client_id(service_id)

    case QMI.Driver.send(control_point.device, request.payload) do
      {:ok, resp} ->
        {:ok, request.decode.(resp)}
    end
  end

  @doc """
  Release a client id for a service
  """
  def release_client_id(control_point) do
    request = Codec.Control.release_client_id(control_point.service_id, control_point.client_id)

    case QMI.Driver.send(control_point.device, request.payload) do
      {:ok, resp} ->
        {:ok, request.decode.(resp)}
    end
  end
end
