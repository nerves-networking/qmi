defmodule QMI.Message do
  @moduledoc false

  alias QMI.Codes

  @type type() :: :response | :indication | :request | :compound | :none | :reserved

  @type t() :: %{
          type: type(),
          transaction_id: 0..65_535,
          message: binary(),
          code: :success | :failure,
          error: 0..65_535 | atom()
        }

  @spec decode(binary()) :: {:ok, t()} | {:error, :bad_qmux_frame}
  def decode(<<0x01, _len::16-little, _flags, service, _client, bin::binary>>) do
    transaction_size = if service == 0x00, do: 8, else: 16
    <<type, transaction::size(transaction_size)-little, message_body::binary>> = bin

    message =
      %{
        type: message_type(service, type),
        message: message_body,
        transaction_id: transaction
      }
      |> get_codes()

    {:ok, message}
  end

  def decode(_), do: {:error, :bad_qmux_frame}

  # types for control service
  defp message_type(0x00, 0x00), do: :request
  defp message_type(0x00, 0x01), do: :response
  defp message_type(0x00, 0x02), do: :indication
  defp message_type(0x00, _), do: :reserved

  # types for services other than control
  defp message_type(_service_id, 0x00), do: :request
  defp message_type(_service_id, 0x01), do: :compound
  defp message_type(_service_id, 0x02), do: :response
  defp message_type(_service_id, 0x04), do: :indication
  defp message_type(_service_id, _), do: :none

  defp get_codes(
         %{
           type: :response,
           message:
             <<_message_id::16-little, _message_size::16-little, 0x02, 0x04::16-little,
               code::16-little, error::16-little, _rest::binary>>
         } = message
       ) do
    message
    |> Map.put(:code, Codes.decode_result_code(code))
    |> Map.put(:error, Codes.decode_error_code(error))
  end

  defp get_codes(message), do: message
end
