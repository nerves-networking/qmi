defmodule QMI do
  @moduledoc """

  """

  @type service() :: :control | :network_access | :wireless_data

  @type request() :: %{payload: iodata(), decode: (binary() -> map())}

  @typedoc """
  Name of the device
  """
  @type device() :: String.t()

  @type control_point() :: %{device: binary(), client_id: byte(), service_id: non_neg_integer()}

  @doc """
  Get a control point for a service to send commands to the modem

  When a client is allocated for a control point, it must manually be released
  by the caller. It is crucial to release control points because allocation may
  fail silently in QMI when a limit as been reached.

  Most tasks will need to immediately release the control point after the request,
  though some may need to keep the client allocated for the duration and used
  in subsequent requests, such as the wireless connection command.
  """
  @spec get_control_point(device(), service()) :: {:ok, control_point()} | {:error, any()}
  def get_control_point(device, service) do
    service_id = service_id(service)

    with {:ok, _driver} <- QMI.Driver.Supervisor.start_driver(device),
         {:ok, resp} <- QMI.Control.get_client_id(%{device: device}, service_id) do
      {:ok, %{client_id: resp.client_id, device: device, service_id: resp.service_id}}
    else
      error -> error
    end
  end

  @doc """
  Release a control point
  """
  @spec release_control_point(control_point()) :: any()
  def release_control_point(control_point) do
    QMI.Control.release_client_id(control_point)
  end

  defp service_id(:control), do: 0x00
  defp service_id(:wireless_data), do: 0x01
  defp service_id(:network_access), do: 0x03
end
