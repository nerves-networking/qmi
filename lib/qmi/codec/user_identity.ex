defmodule QMI.Codec.UserIdentity do
  @moduledoc """
  Codec for making user identity service requests
  """

  @read_transparent 0x0020

  @typedoc """
  The response from issuing a read transparent request
  """
  @type read_transparent_response() :: %{
          sw1_result_code: non_neg_integer() | nil,
          sw2_result_code: non_neg_integer() | nil,
          read_result: binary() | nil
        }

  @doc """
  Read any transparent file in the card and access by path
  """
  @spec read_transparent(non_neg_integer(), non_neg_integer()) :: QMI.request()
  def read_transparent(file_id, file_path) do
    session = session_tlv()
    file = file_id_tlv(file_id, file_path)
    read_info = read_info_tlv()
    tlvs = <<session::binary, file::binary, read_info::binary>>

    size = byte_size(tlvs)

    %{
      service_id: 0x0B,
      payload: [<<@read_transparent::16-little, size::16-little>>, tlvs],
      decode: &parse/1
    }
  end

  defp session_tlv() do
    <<0x01, 0x02, 0x00, 0x00, 0x00>>
  end

  defp file_id_tlv(file_id, file_path) do
    <<0x02, 0x05, 0x00, file_id::16-little, 0x02, file_path::16-little>>
  end

  defp read_info_tlv() do
    <<0x03, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00>>
  end

  defp parse(<<@read_transparent::16-little, size::16-little, tlvs::size(size)-binary>>) do
    %{sw1_result_code: nil, sw2_result_code: nil, read_result: nil}
    |> parse_tlvs(tlvs)
  end

  defp parse(_other) do
    {:error, :unexpected_response}
  end

  defp parse_tlvs(result, <<>>) do
    {:ok, result}
  end

  defp parse_tlvs(
         result,
         <<0x11, _size::16-little, content_len::16-little, bytes::size(content_len)-binary,
           rest::binary>>
       ) do
    result
    |> Map.put(:read_result, bytes)
    |> parse_tlvs(rest)
  end

  defp parse_tlvs(result, <<0x10, 0x02::16-little, sw1_code, sw2_code, rest::binary>>) do
    result
    |> Map.put(:sw1_result_code, sw1_code)
    |> Map.put(:sw2_result_code, sw2_code)
    |> parse_tlvs(rest)
  end

  defp parse_tlvs(result, <<_type, size::16-little, _values::size(size)-binary, rest::binary>>) do
    parse_tlvs(result, rest)
  end
end
