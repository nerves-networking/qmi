defmodule QMI.Control.ReleaseClientIdResp do
  @moduledoc """
  Response to releasing a client id
  """

  @type t() :: %__MODULE__{
          service_type: non_neg_integer(),
          client_id: non_neg_integer()
        }

  defstruct service_type: nil, client_id: nil

  defimpl QMI.Response do
    def parse_tlvs(response, <<1, 2::little-16, service_type, client_id>>) do
      %QMI.Control.ReleaseClientIdResp{
        response
        | service_type: service_type,
          client_id: client_id
      }
    end
  end
end
