defmodule QMI.WirelessData do
  @moduledoc """
  Provides command related to wireless messaging
  """

  alias QMI.Codec

  @doc """
  Start the network interface
  """
  @spec start_network_interface(QMI.t(), [
          Codec.WirelessData.start_network_interface_opt()
        ]) :: {:ok, map()} | {:error, atom()}
  def start_network_interface(qmi, opts \\ []) do
    Codec.WirelessData.start_network_interface(opts)
    |> QMI.call(qmi)
  end
end
