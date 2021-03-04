defmodule QMI.Control.GetClientIdReq do
  @moduledoc """
  Request a client id from the specified QMI service
  """

  @type t() :: %__MODULE__{
          service_type: non_neg_integer()
        }

  defstruct service_type: nil

  defimpl QMI.Request do
    def encode(%{service_type: service_type}) do
      <<0x0022::little-16, 4, 0, 1, 1, 0, service_type>>
    end
  end
end
