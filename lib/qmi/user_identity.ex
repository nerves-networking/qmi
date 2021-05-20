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
end
