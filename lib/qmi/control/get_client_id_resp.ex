defmodule QMI.Control.GetClientIdResp do
  defstruct service_type: nil, client_id: nil

  defimpl QMI.Response do
    def parse_tlvs(response, <<1, 2::little-16, service, client_id>>) do
      %QMI.Control.GetClientIdResp{response | service_type: service, client_id: client_id}
    end
  end
end
