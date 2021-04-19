defmodule QMI.NetworkAccess do
  @moduledoc """
  Provides commands related to network access
  """
  alias QMI.Codec

  @doc """
  Get the current signal strength
  """
  @spec get_signal_strength(QMI.t()) :: {:ok, map()} | {:error, atom()}
  def get_signal_strength(qmi) do
    Codec.NetworkAccess.get_signal_strength()
    |> QMI.call(qmi)
  end

  @spec get_home_network(QMI.t()) :: {:ok, map()} | {:error, atom()}
  def get_home_network(qmi) do
    Codec.NetworkAccess.get_home_network()
    |> QMI.call(qmi)
  end
end
