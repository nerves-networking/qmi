defmodule QMI.Control.ReleaseClientIdResp do
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
