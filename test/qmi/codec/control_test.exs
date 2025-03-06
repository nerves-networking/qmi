# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.Codec.ControlTest do
  use ExUnit.Case

  alias QMI.Codec.Control

  test "get_client_id/1" do
    request = Control.get_client_id(0x03)

    assert request.service_id == 0x00

    assert IO.iodata_to_binary(request.payload) ==
             <<0x22::little-16, 0x04::little-16, 0x01, 0x01::little-16, 0x03>>

    assert request.decode.(
             <<0x22::little-16, 0x05::little-16, 0x01, 0x02::little-16, 0x03, 0x04>>
           ) == {:ok, 4}
  end

  test "release_client_id/1" do
    request = Control.release_client_id(0x03, 0x04)

    assert request.service_id == 0x00

    assert IO.iodata_to_binary(request.payload) ==
             <<0x23::little-16, 0x05::little-16, 0x01, 0x02::little-16, 0x03, 0x04>>

    assert request.decode.(
             <<0x23::little-16, 0x05::little-16, 0x01, 0x02::little-16, 0x03, 0x04>>
           ) == :ok
  end

  test "parse_indication/1 for sync indication" do
    indication = <<0x27, 0x00, 0x00, 0x00>>

    assert {:ok, %{name: :sync_indication}} = Control.parse_indication(indication)
  end
end
