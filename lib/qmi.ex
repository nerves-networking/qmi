defmodule QMI do
  @type client_id :: non_neg_integer()
  @type service :: non_neg_integer()
  @type control_point :: {service(), client_id()}

  @typedoc """
  Name of the device
  """
  @type device :: String.t()

  alias QMI.Service.DeviceManagement

  defdelegate get_control_point(driver, service), to: QMI.Service.Control
  defdelegate release_control_point(driver, cp), to: QMI.Service.Control

  @doc """
  Get the operating state of the modem
  """
  def get_operating_state(device) do
    cp = get_control_point(device, DeviceManagement.id())

    response = DeviceManagement.get_operating_state_mode(device, cp)

    release_control_point(device, cp)

    response
  end

  def start_driver(device \\ "/dev/cdc-wdm0") do
    # Will change in the future to not be so drastic, just
    # was wanting to make working with this at the command line
    # a little nicer for testing.
    case QMI.Driver.Supervisor.start_driver(device) do
      {:ok, driver} ->
        driver

      {:error, {:already_started, driver}} ->
        driver
    end
  end
end
