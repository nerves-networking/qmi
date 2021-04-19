defmodule QMI.Message do
  alias QMI.Codes

  @moduledoc """
  QMI message structures and handling

  Based on definitions from https://gitlab.freedesktop.org/mobile-broadband/libqmi/-/blob/master/src/libqmi-glib/qmi-message.c
  tlv = Type-Length-Value
  """

  @type type :: :response | :indication | :request

  @type t :: %__MODULE__{
          length: integer(),
          flags: integer(),
          service: module(),
          client: integer(),
          code: :success | :failure,
          error: integer() | atom(),
          type: type(),
          transaction: integer(),
          id: integer(),
          tlvs: [map()] | binary() | map(),
          service_msg_bin: binary()
        }

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
    :tlvs,
    :raw,
    :service_msg_bin
  ]

  def decode(<<1, len::16-little, flags, service, client, bin::binary>> = raw) do
    {type, transaction, service_msg_bin} = pop_type_and_transaction(service, bin)

    ##
    # I only have partial messages right now, so let the length slide by here.
    # Change later to be more strict on checking length
    #
    # <<msg_id::16-little, msg_len::16-little, result_and_tlvs::binary-size(msg_len)>> = service_msg_bin
    #
    <<msg_id::16-little, _msg_len::16-little, raw_tlvs::binary>> = service_msg_bin

    %__MODULE__{
      length: len,
      flags: flags,
      service: service,
      client: client,
      type: type,
      transaction: transaction,
      id: msg_id,
      tlvs: raw_tlvs,
      raw: raw,
      service_msg_bin: service_msg_bin
    }
    |> maybe_decode_tlvs()
  end

  def decode(_), do: {:error, :bad_qmux_frame}

  defp maybe_decode_tlvs(%{type: :response} = message) do
    # Every response _should_ have a result TLV first
    # Pop the code and error from result TLV before attempting to decode tlvs
    <<2, 4::16-little, code::16-little, error::16-little, raw_tlvs::binary>> = message.tlvs

    message = %{
      message
      | code: Codes.decode_result_code(code),
        error: Codes.decode_error_code(error),
        tlvs: raw_tlvs
    }

    message
  end

  defp maybe_decode_tlvs(%{type: :indication} = message) do
    message
  end

  defp maybe_decode_tlvs(message), do: message

  # If the message is a QMI_CTL message, transaction is only 1 byte
  defp pop_type_and_transaction(0x00, <<type, transaction, rest::binary>>) do
    type =
      case type do
        0 -> :request
        1 -> :response
        2 -> :indication
        _ -> :reserved
      end

    {type, transaction, rest}
  end

  defp pop_type_and_transaction(_service, <<type, transaction::16-little, rest::binary>>) do
    type =
      case type do
        0 -> :request
        1 -> :compound
        2 -> :response
        4 -> :indication
        _ -> :none
      end

    {type, transaction, rest}
  end
end
