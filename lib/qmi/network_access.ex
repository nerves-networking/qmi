defmodule QMI.NetworkAccess do
  @moduledoc """
  Provides commands related to network access
  """
  alias QMI.Codec

  @doc """
  Get the current signal strength
  """
  @spec get_signal_strength(QMI.name()) ::
          {:ok, Codec.NetworkAccess.signal_strength_report()} | {:error, atom()}
  def get_signal_strength(qmi) do
    Codec.NetworkAccess.get_signal_strength()
    |> QMI.call(qmi)
  end

  @doc """
  Get the home network of the device

  This returns the MCC, MNC, and service provider for the network.
  """
  @spec get_home_network(QMI.name()) ::
          {:ok, Codec.NetworkAccess.home_network_report()} | {:error, atom()}
  def get_home_network(qmi) do
    Codec.NetworkAccess.get_home_network()
    |> QMI.call(qmi)
  end

  @spec get_rf_band_info(QMI.name()) ::
          {:ok, [Codec.NetworkAccess.rf_band_information()]} | {:error, atom()}
  def get_rf_band_info(qmi) do
    Codec.NetworkAccess.get_rf_band_info()
    |> QMI.call(qmi)
  end

  @doc """
  Get the system selection preferences
  """
  @spec get_system_selection_preference(QMI.name()) ::
          {:ok, Codec.NetworkAccess.get_system_selection_preference_response()} | {:error, atom()}
  def get_system_selection_preference(qmi) do
    Codec.NetworkAccess.get_system_selection_preference()
    |> QMI.call(qmi)
  end

  @doc """
  Set the system selection preferences
  """
  @spec set_system_selection_preference(QMI.name(), [
          Codec.NetworkAccess.set_system_selection_preference_opt()
        ]) :: :ok | {:error, atom()}
  def set_system_selection_preference(qmi, opts \\ []) do
    opts
    |> Codec.NetworkAccess.set_system_selection_preference()
    |> QMI.call(qmi)
  end
end
