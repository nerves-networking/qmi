# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.Codec.Indication do
  @moduledoc false

  # Parser for indications

  @doc """
  Route the indication to the appropriate parser.
  """
  @spec parse(QMI.Message.t()) :: {:ok, map()} | {:error, :invalid_indication}
  def parse(%{service_id: 0} = message) do
    QMI.Codec.Control.parse_indication(message.message)
  end

  def parse(%{service_id: 1} = message) do
    QMI.Codec.WirelessData.parse_indication(message.message)
  end

  def parse(%{service_id: 3} = message) do
    QMI.Codec.NetworkAccess.parse_indication(message.message)
  end

  def parse(_message) do
    {:error, :invalid_indication}
  end
end
