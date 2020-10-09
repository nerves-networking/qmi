defmodule QMI.Response do
  defstruct [
    :length,
    :flags,
    :service,
    :client,
    :code,
    :error,
    :type,
    :transaction,
    :id,
    :tlvs
  ]

  defguard is_response(service, type)
           when (service == 0 and type == 1) or (service > 0 and type == 2)

  def decode(<<1, len::16-little, flags, service, client, type, bin::binary>>)
      when is_response(service, type) do
    service = decode_service(service)
    {transaction, service_msg_bin} = pop_transaction(service, bin)

    ##
    # TODO: I only have partial messages right now, so let the length slide by here.
    # Change later to be more strict on checking length
    #
    # <<msg_id::16-little, msg_len::16-little, result_and_tlvs::binary-size(msg_len)>> = service_msg_bin
    #
    <<msg_id::16-little, _msg_len::16-little, result_and_tlvs::binary>> = service_msg_bin

    # Pop the result TLV
    <<2, 4::16-little, code::16-little, error::16-little, raw_tlvs::binary>> = result_and_tlvs

    %__MODULE__{
      length: len,
      flags: flags,
      service: service,
      client: client,
      type: :response,
      transaction: transaction,
      id: msg_id,
      code: code,
      error: error,
      tlvs: raw_tlvs
    }
    |> maybe_decode_tlvs()
  end

  def decode(_), do: {:error, :bad_qmux_frame}

  defp decode_service(service) do
    case service do
      # :QMI_CTL
      0x00 -> QMI.ControlService
      # :QMI_WDS
      0x01 -> QMI.WirelessDataService
      # :QMI_DMS
      0x02 -> QMI.DeviceManagementService
      # :QMI_NAS
      0x03 -> QMI.NetworkAccessService
      # :QMI_WMS
      0x05 -> QMI.WirelessMessagingService
      # :QMI_UIM
      0x0B -> QMI.UserIdentityModuleService
      # :QMI_LOC
      0x10 -> QMI.LocationService
      # :QMI_PDC
      0x24 -> QMI.PersistentDeviceConfigurationService
      # :QMI_FOTA
      0xE6 -> QMI.FirmwareOverTheAirService
      # :QMI_GMS
      0xE7 -> QMI.TelitGeneralModemService
      # :QMI_GAS
      0xE8 -> QMI.TelitGeneralApplicationService
      _ -> :unknown
    end
  end

  defp maybe_decode_tlvs(response) do
    if function_exported?(response.service, :decode_response_tlvs, 1) do
      response.service.decode_response_tlvs(response)
    else
      response
    end
  end

  # If the message is a QMI_CTL message, transaction is only 1 byte
  defp pop_transaction(QMI.ControlService, <<transaction, rest::binary>>) do
    {transaction, rest}
  end

  defp pop_transaction(_service, <<transaction::16-little, rest::binary>>) do
    {transaction, rest}
  end
end
