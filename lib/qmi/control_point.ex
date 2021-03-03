defmodule QMI.ControlPoint do
  @moduledoc """
  A control point for sending QMI commands to a modem
  """

  @type client_id() :: non_neg_integer()

  @type service() ::
          QMI.Service.Control
          | QMI.Service.DeviceManagement
          | QMI.Service.NetworkAccess
          | QMI.Service.WirelessData

  @type t() :: %__MODULE__{
          client_id: client_id(),
          service: service(),
          device: QMI.device()
        }

  defstruct client_id: nil, service: nil, device: nil
end
