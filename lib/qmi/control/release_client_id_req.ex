defmodule QMI.Control.ReleaseClientIdReq do
  @moduledoc """
  Request to release a perviously assigned client id
  """

  @type t() :: %__MODULE__{
          client_id: non_neg_integer(),
          service_type: non_neg_integer()
        }

  defstruct client_id: nil, service_type: nil

  defimpl QMI.Request do
    def encode(%{client_id: client_id, service_type: service_type}) do
      <<0x0023::16-little, 5, 0, 1, 2, 0, service_type, client_id>>
    end
  end
end
