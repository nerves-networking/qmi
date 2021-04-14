defmodule QMI.WirelessData do
  @moduledoc """

  """

  alias QMI.Codec

  @doc """
  Start the network interface
  """
  @spec start_network_interface(QMI.control_point(), [
          Codec.WirelessData.start_network_interface_opt()
        ]) :: {:ok, map()}
  def start_network_interface(control_point, opts \\ []) do
    request = Codec.WirelessData.start_network_interface(opts)

    case QMI.Driver.send(control_point.device, request.payload,
           client_id: control_point.client_id,
           service_id: control_point.service_id
         ) do
      {:ok, resp} ->
        {:ok, request.decode.(resp)}
    end
  end
end
