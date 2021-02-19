defmodule QMI do
  @type client_id :: non_neg_integer()
  @type service :: non_neg_integer()
  @type control_point :: {service(), client_id()}

  alias QMI.Service.DeviceManagement

  defdelegate get_control_point(driver, service), to: QMI.Service.Control
  defdelegate release_control_point(driver, cp), to: QMI.Service.Control

  @doc """
  Get the operating state of the modem
  """
  def get_operating_state() do
    driver = start_driver()
    cp = get_control_point(driver, DeviceManagement.id())

    response = DeviceManagement.get_operating_state_mode(drive, cp)

    release_control_point(driver, cp)

    response
  end

  defp start_driver() do
    # Will change in the future to not be so drastic, just
    # was wanting to make working with this at the command line
    # a little nicer for testing.
    case QMI.Driver.start_link("/dev/cdc-wdm0") do
      {:ok, driver} ->
        driver

      {:error, {:already_started, driver}} ->
        driver
    end
  end
end
