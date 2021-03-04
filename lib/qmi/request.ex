defprotocol QMI.Request do
  @moduledoc """
  Protocol for QMI services message that should be encoded into binary form
  to be sent to the device
  """

  @doc """
  Encode the request into its binary format
  """
  @spec encode(t()) :: binary()
  def encode(request)
end
