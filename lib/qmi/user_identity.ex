# SPDX-FileCopyrightText: 2021 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.UserIdentity do
  @moduledoc """
  Provides commands related to the user identity service
  """

  alias QMI.Codec

  @doc """
  Send a request to read a transparent file
  """
  @spec read_transparent(QMI.name(), non_neg_integer(), non_neg_integer()) ::
          {:ok, Codec.UserIdentity.read_transparent_response()} | {:error, atom()}
  def read_transparent(qmi, file_id, file_path) do
    Codec.UserIdentity.read_transparent(file_id, file_path)
    |> QMI.call(qmi)
  end

  @doc """
  Parse a raw binary ICCID

  Call `read_transparent/3` to get the raw binary CCID.

  ### Examples

     iex> raw_binary = <<0x64, 0x73, 0x3, 0x4, 0x0, 0x0, 0x10, 0x52, 0x70, 0x20>>
     iex> QMI.UserIdentity.parse_iccid(raw_binary)
     "46373040000001250702"
  """
  @spec parse_iccid(binary()) :: binary()
  def parse_iccid(binary) do
    for <<a::4, b::4 <- binary>>, into: "" do
      int_to_string(b * 10 + a)
    end
  end

  defp int_to_string(x) when x < 10, do: "0" <> Integer.to_string(x)
  defp int_to_string(x), do: Integer.to_string(x)
end
