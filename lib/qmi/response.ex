defprotocol QMI.Response do
  @moduledoc """
  Protocol for QMI responses to have their TLV values parsed into an Elixir
  data stricture
  """

  @doc """
  Parse the binary format of the response TLV values
  """
  @spec parse_tlvs(t(), binary()) :: t()
  def parse_tlvs(response, binary)
end
