defmodule QMI.NetworkAccess do
  @moduledoc """
  Provides commands related to network access
  """
  alias QMI.Codec

  @doc """
  Get the current signal strength
  """
  @spec get_signal_strength(QMI.t()) ::
          {:ok, Codec.NetworkAccess.signal_strength_report()} | {:error, atom()}
  def get_signal_strength(qmi) do
    Codec.NetworkAccess.get_signal_strength()
    |> QMI.call(qmi)
  end

  @doc """
  Get the home network of the device

  This returns the MCC and MNC of the device.
  """
  @spec get_home_network(QMI.t()) ::
          {:ok, Codec.NetworkAccess.home_network_report()} | {:error, atom()}
  def get_home_network(qmi) do
    Codec.NetworkAccess.get_home_network()
    |> QMI.call(qmi)
  end
end
