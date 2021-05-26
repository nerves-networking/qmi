defmodule QMI.Codec.Indication do
  @moduledoc false

  # Parser for indications

  @doc """
  Route the indication to the appropriate parser.
  """
  @spec parse(QMI.Message.t()) :: {:ok, map()} | {:error, :invalid_indication}
  def parse(%{service_id: 3} = message) do
    QMI.Codec.NetworkAccess.parse_indication(message.message)
  end

  def parse(_message) do
    {:error, :invalid_indication}
  end
end
