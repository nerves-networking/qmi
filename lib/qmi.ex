defmodule QMI do
  @type client_id :: non_neg_integer()
  @type service :: non_neg_integer()
  @type control_point :: {service(), client_id()}

  defdelegate get_control_point(driver, service), to: QMI.Service.Control
  defdelegate release_control_point(driver, cp), to: QMI.Service.Control
end
