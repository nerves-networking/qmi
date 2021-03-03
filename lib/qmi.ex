defmodule QMI do
  @type service :: non_neg_integer()

  @typedoc """
  Name of the device
  """
  @type device :: String.t()

  alias QMI.ControlPoint
  alias QMI.Service.{Control, DeviceManagement}

  @doc """
  Get a control point for a service to send commands to the modem

  When a client is allocated for a control point, it must manually be released
  by the caller. It is crucial to release control points because allocation may
  fail silently in QMI when a limit as been reached.

  Most tasks will need to immediately release the control point after the request,
  though some may need to keep the client allocated for the duration and used
  in subsequent requests, such as the wireless connection command.
  """
  @spec get_control_point(device(), module()) :: {:ok, ControlPoint.t()} | {:error, any()}
  def get_control_point(device, service) do
    with {:ok, _driver} <- QMI.Driver.Supervisor.start_driver(device),
         {:ok, client_id} <- Control.get_client_id(device, service.id) do
      {:ok, %ControlPoint{client_id: client_id, device: device, service: service}}
    else
      error -> error
    end
  end

  @doc """
  Release a control point
  """
  @spec release_control_point(ControlPoint.t()) :: any()
  def release_control_point(%ControlPoint{} = cp) do
    service_id = cp.service.id()
    Control.release_client_id(cp.device, {service_id, cp.client_id})
  end

  @doc """
  Get the operating state of the modem
  """
  @spec get_operating_state(ControlPoint.t()) :: {:ok, atom()} | {:error, any()}
  def get_operating_state(%ControlPoint{} = cp) do
    service_id = cp.service.id()

    case DeviceManagement.get_operating_state_mode(cp.device, {service_id, cp.client_id}) do
      {:ok, message} ->
        {:ok, Keyword.fetch!(message.tlvs, :mode)}

      error ->
        error
    end
  end
end
