defmodule QMI.ControlService do
  @get_client_id 0x0022
  @release_client_id 0x0023

  def decode_response_tlvs(%{code: code} = resp) when code > 0 do
    # Response almost never has more TLV's if the command
    # was not successful. Just assume skip all for now
    resp
  end

  def decode_response_tlvs(%{id: @get_client_id, tlvs: raw_tlvs} = resp) do
    <<1, 2::little-16, service, client_id>> = raw_tlvs
    %{resp | tlvs: [%{service: service, client_id: client_id}]}
  end

  def decode_response_tlvs(%{id: @release_client_id, tlvs: raw_tlvs} = resp) do
    <<1, 2::little-16, service, client_id>> = raw_tlvs
    %{resp | tlvs: [%{service: service, client_id: client_id}]}
  end
end
