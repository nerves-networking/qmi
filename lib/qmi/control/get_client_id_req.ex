defmodule QMI.Control.GetClientIdReq do
  @type t() :: %__MODULE__{
          service_type: non_neg_integer()
        }

  defstruct service_type: nil

  defimpl QMI.Request do
    @get_client_id 0x0022

    def encode(%{service_type: service_type}) do
      <<@get_client_id::little-16, 4, 0, 1, 1, 0, service_type>>
    end
  end
end
