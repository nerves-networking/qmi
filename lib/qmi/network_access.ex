defmodule QMI.NetworkAccess do
  alias QMI.Codec

  @moduledoc """

  """

  @doc """
  Get the current signal strength
  """
  @spec get_signal_strength(term()) :: map()
  def get_signal_strength(qmi) do
    request = Codec.NetworkAccess.get_signal_strength()
    service_name = :network_access

    {:ok, control_point} = ControlPointCache.get_control_point(qmi, service_name)
    {:ok, resp} = QMI.Driver.send(control_point, request.payload)
    request.decode.(resp)
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
