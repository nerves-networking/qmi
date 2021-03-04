defmodule QMI.Control.GetClientIdResp do
  @moduledoc """
  Response that contains the client id allocated from a client id request
  """

  @type t() :: %__MODULE__{
          service_type: non_neg_integer(),
          client_id: non_neg_integer()
        }

  defstruct service_type: nil, client_id: nil

  defimpl QMI.Response do
    def parse_tlvs(response, <<1, 2::little-16, service, client_id>>) do
      %QMI.Control.GetClientIdResp{response | service_type: service, client_id: client_id}
    end
  end
end
