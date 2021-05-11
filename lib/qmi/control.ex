defmodule QMI.Control do
  @moduledoc """
  Provides commands related to QMUX link and client management
  """
  alias QMI.Codec

  @doc """
  Get a client id for a service
  """
  @spec get_client_id(QMI.name(), non_neg_integer()) ::
          {:ok, non_neg_integer()} | {:error, atom()}
  def get_client_id(qmi, service_id) do
    Codec.Control.get_client_id(service_id)
    |> QMI.call(qmi)
  end

  @doc """
  Release a client id for a service
  """
  @spec release_client_id(QMI.name(), non_neg_integer(), non_neg_integer()) ::
          :ok | {:error, atom()}
  def release_client_id(qmi, service_id, client_id) do
    Codec.Control.release_client_id(service_id, client_id)
    |> QMI.call(qmi)
  end
end
