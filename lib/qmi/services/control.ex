defmodule QMI.Service.Control do
  use QMI.Service, id: 0x00

  # Control is used to request clients and service
  # control points, so the client_id and service must be 0
  # since it doesn't need a control point for itself
  @default_control_point {0, 0}

  @get_client_id 0x0022
  @release_client_id 0x0023

  alias QMI.ControlPoint

  @doc false
  @impl QMI.Service
  def decode_response_tlvs(%{code: :failure} = resp) do
    # Response almost never has more TLV's if the command
    # was not successful. Just assume skip all for now
    resp
  end

  def decode_response_tlvs(%{id: @get_client_id, tlvs: raw_tlvs} = resp) do
    <<1, 2::little-16, service, client_id>> = raw_tlvs
    %{resp | tlvs: [%{service: service, client_id: client_id}]}
  end

  def decode_response_tlvs(%{id: @release_client_id, tlvs: raw_tlvs} = resp) do
    <<1, 2::little-16, service, client_id>> = raw_tlvs
    %{resp | tlvs: [%{service: service, client_id: client_id}]}
  end

  def decode_response_tlvs(message) do
    message
  end

  ##
  # Requests
  @doc """
  Get a control point for a specific service

  #{File.read!("README.md") |> String.split(~r/<!-- CPDOC !-->/) |> Enum.drop(1) |> hd()}
  """
  @spec get_client_id(QMI.device(), QMI.service()) ::
          {:ok, ControlPoint.client_id()} | {:error, QMI.Driver.response()}
  def get_client_id(device, service) do
    # TODO: Maybe change service to be atom that gets mapped?
    bin = <<@get_client_id::little-16, 4, 0, 1, 1, 0, service>>

    case QMI.Driver.request(device, bin, @default_control_point) do
      {:ok, %{tlvs: [%{client_id: client_id, service: ^service}]}} ->
        {:ok, client_id}

      msg ->
        # This probably isn't _really_ an error but makes pattern matching easier for now
        # from the call site.
        {:error, msg}
    end
  end

  @doc """
  Release a client id

  When a client is allocated for a control point, it must manually be released
  by the caller. It is crucial to release control points.
  """
  @spec release_client_id(QMI.device(), tuple()) :: QMI.Driver.response()
  def release_client_id(device, {service, client}) do
    bin = <<@release_client_id::16-little, 5, 0, 1, 2, 0, service, client>>

    QMI.Driver.request(device, bin, @default_control_point)
  end
end
