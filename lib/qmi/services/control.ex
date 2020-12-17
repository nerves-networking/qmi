defmodule QMI.Service.Control do
  use QMI.Service, id: 0x00

  # Control is used to request clients and service
  # control points, so the client_id and service must be 0
  # since it doesn't need a control point for itself
  @default_control_point {0, 0}

  @get_client_id 0x0022
  @release_client_id 0x0023

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

  ##
  # Requests
  @doc """
  Get a control point for a specific service

  #{File.read!("README.md") |> String.split(~r/<!-- CPDOC !-->/) |> Enum.drop(1) |> hd()}
  """
  @spec get_control_point(GenServer.server(), QMI.service()) ::
          QMI.control_point() | QMI.Driver.response()
  def get_control_point(driver, service) do
    # TODO: Maybe change service to be atom that gets mapped?
    bin = <<34, 0, 4, 0, 1, 1, 0, service>>

    case QMI.Driver.request(driver, bin, @default_control_point) do
      {:ok, %{tlvs: [%{client_id: client_id, service: service}]}} ->
        {service, client_id}

      msg ->
        msg
    end
  end

  @doc """
  Release a control point

  When a client is allocated for a control point, it must manually be released
  by the caller. It is crucial to release control points.
  """
  @spec release_control_point(GenServer.name(), QMI.control_point()) :: QMI.Driver.response()
  def release_control_point(driver, {service, client} = cp) do
    bin = <<@release_client_id::16-little, 5, 0, 1, 2, 0, service, client>>

    QMI.Driver.request(driver, bin, cp)
  end
end
