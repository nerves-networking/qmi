defmodule QMI.Control.ReleaseClientIdReq do
  defstruct client_id: nil, service_type: nil

  defimpl QMI.Request do
    @release_client_id 0x0023

    def encode(%{client_id: client_id, service_type: service_type}) do
      <<@release_client_id::16-little, 5, 0, 1, 2, 0, service_type, client_id>>
    end
  end
end
