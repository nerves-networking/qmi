defmodule QMI.NetworkAccess do
  alias QMI.Codec

  def get_signal_strength(control_point) do
    request = Codec.NetworkAccess.get_signal_strength()

    case QMI.Driver.send(control_point.device, request.payload,
           client_id: control_point.client_id,
           service_id: control_point.service_id
         ) do
      {:ok, resp} ->
        {:ok, request.decode.(resp)}
    end
  end

  def get_home_network(control_point) do
    request = Codec.NetworkAccess.get_home_network()

    case QMI.Driver.send(control_point.device, request.payload,
           client_id: control_point.client_id,
           service_id: control_point.service_id
         ) do
      {:ok, resp} -> {:ok, request.decode.(resp)}
    end
  end
end
