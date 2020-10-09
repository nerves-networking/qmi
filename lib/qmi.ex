defmodule Qmi do
  @control_service 0
  @nas_service 3

  def get_signal_strength(dev \\ "/dev/cdc-wdm0") do
    %{client_id: client_id, service: service} = get_client_id(dev, @nas_service)
    sig_res = get_signal_strength(dev, client_id)
    _ = release_client_id(dev, client_id, service)
    sig_res
  end

  defp get_response(dev, bin) do
    # FRANK HELP HERE ¬
    # Send bin to /dev/cdc-wdm0
    # Read response from /dev/cdc-wdm0
    # Parse response to map/struct
    QMI.Response.decode(bin)
  end

  defp get_client_id(dev, service) do
    # TODO: increment transaction
    bin = <<1, 15, 0, 0, 0, 0, 0, 1, 34, 0, 4, 0, 1, 1, 0, service>>
    res = get_response(dev, bin)
    [tlv] = res.tlvs
    tlv
  end

  defp get_signal_strength(dev, client) do
    nas_get_sig_id = 32

    bin =
      <<1, 17, 0, 0, @nas_service, client, 0, 1, 0, nas_get_sig_id::16-little, 5, 0, 16, 2, 0,
        239, 0>>

    get_response(dev, bin)
  end

  defp release_client_id(dev, client, service) do
    ctl_release_client_id = 35

    bin =
      <<1, 16, 0, 0, @control_service, 0, 0, 2, ctl_release_client_id::16-little, 5, 0, 1, 2, 0,
        service, client>>

    get_response(dev, bin)
  end
end
