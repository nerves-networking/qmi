# SPDX-FileCopyrightText: 2025 Marc Lainez
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.WirelessDataAdmin do
  @moduledoc """
  Commands for the QMI WDA (Wireless Data Administrative) service.

  This service configures the data format used between the modem and the host
  driver.  The key operation is `set_data_format/2`, which must be called
  **before** starting a data session to ensure the modem and driver agree on
  whether the data path uses raw-IP or 802.3 (Ethernet) framing.
  """

  alias QMI.Codec

  @doc """
  Query the modem's current data format.

  ## Example

      {:ok, %{link_layer_protocol: :raw_ip}} =
        QMI.WirelessDataAdmin.get_data_format(MyApp.QMI)
  """
  @spec get_data_format(QMI.name()) ::
          {:ok, Codec.WirelessDataAdmin.data_format()} | {:error, atom()}
  def get_data_format(qmi) do
    Codec.WirelessDataAdmin.get_data_format()
    |> QMI.call(qmi)
  end

  @doc """
  Set the data format on the modem.

  This must be called before `QMI.WirelessData.start_network_interface/2`
  so that the modem sends packets in the format the driver expects.

  ## Options

  * `:link_layer_protocol` – `:raw_ip` or `:"802.3"` (required)
  * `:ul_aggregation_protocol` – uplink aggregation (default `:disabled`)
  * `:dl_aggregation_protocol` – downlink aggregation (default `:disabled`)
  * `:qos_format` – include QoS headers (default `false`)

  ## Example

      :ok = QMI.WirelessDataAdmin.set_data_format(MyApp.QMI,
        link_layer_protocol: :raw_ip,
        ul_aggregation_protocol: :disabled,
        dl_aggregation_protocol: :disabled
      )
  """
  @spec set_data_format(QMI.name(), [Codec.WirelessDataAdmin.set_data_format_opt()]) ::
          {:ok, Codec.WirelessDataAdmin.data_format()} | {:error, atom()}
  def set_data_format(qmi, opts) do
    Codec.WirelessDataAdmin.set_data_format(opts)
    |> QMI.call(qmi)
  end
end
