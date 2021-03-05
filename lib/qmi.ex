defmodule QMI do
  @type service :: non_neg_integer()

  @typedoc """
  Name of the device
  """
  @type device :: String.t()

  alias QMI.{
    Control,
    ControlPoint,
    DeviceManagement,
    Driver,
    Message,
    Request,
    Response,
    WirelessData
  }

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
    with {:ok, _driver} <- Driver.Supervisor.start_driver(device),
         request <- %Control.GetClientIdReq{service_type: service.id()},
         {:ok, message} <- send_control_request(device, request) do
      client_id_resp = Response.parse_tlvs(%Control.GetClientIdResp{}, message.tlvs)

      {:ok, %ControlPoint{client_id: client_id_resp.client_id, service: service, device: device}}
    end
  end

  @doc """
  Release a control point
  """
  @spec release_control_point(ControlPoint.t()) :: :ok
  def release_control_point(%ControlPoint{} = cp) do
    request = %Control.ReleaseClientIdReq{service_type: cp.service.id(), client_id: cp.client_id}

    case send_request(cp, request) do
      {:ok, _message} ->
        :ok
    end
  end

  @doc """
  Get the operating state of the modem
  """
  @spec get_operating_state(ControlPoint.t()) ::
          {:ok, DeviceManagement.GetOperatingModeResp.t()} | {:error, any()}
  def get_operating_state(%ControlPoint{} = cp) do
    request = %DeviceManagement.GetOperatingModeReq{}

    case send_request(cp, request) do
      {:ok, message} ->
        {:ok, Response.parse_tlvs(%DeviceManagement.GetOperatingModeResp{}, message.tlvs)}
    end
  end

  @doc """
  Start a network connection to a service provider

  If this command completes successfully you can perform IP configuration for
  the interface.
  """
  @spec start_network_connection(ControlPoint.t(), String.t()) ::
          {:ok, WirelessData.StartNetworkInterfaceResp.t()} | {:error, any()}
  def start_network_connection(control_point, service_provider) do
    request = %WirelessData.StartNetworkInterfaceReq{apn_name: service_provider}

    case send_request(control_point, request) do
      {:ok, message} ->
        {:ok, Response.parse_tlvs(%WirelessData.StartNetworkInterfaceResp{}, message.tlvs)}

      error ->
        error
    end
  end

  @doc """
  Send a request to the modem
  """
  @spec send_request(ControlPoint.t(), Request.t()) ::
          {:ok, Message.t()} | {:error, Message.t() | :timeout}
  def send_request(control_point, request) do
    %ControlPoint{service: service, client_id: client_id, device: device} = control_point
    binary = Request.encode(request)

    Driver.request(device, binary, {service.id(), client_id})
  end

  defp send_control_request(device, request) do
    binary = Request.encode(request)

    Driver.request(device, binary, {0, 0})
  end
end
