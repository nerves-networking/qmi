# SPDX-FileCopyrightText: 2021 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.Codec.UserIdentityTest do
  use ExUnit.Case, async: true

  alias QMI.Codec.UserIdentity

  test "read_transparent/2" do
    request = UserIdentity.read_transparent(0x2FE2, 0x3F00)

    assert IO.iodata_to_binary(request.payload) ==
             <<0x20::16-little, 0x14::16-little, 0x01, 0x02, 0x00, 0x00, 0x00, 0x02, 0x05, 0x00,
               0x0E2, 0x2F, 0x02, 0x00, 0x3F, 0x03, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00>>

    assert request.service_id == 0x0B

    assert request.decode.(
             <<32, 0, 27, 0, 2, 4, 0, 0, 0, 0, 0, 17, 12, 0, 10, 0, 152, 136, 3, 7, 0, 0, 16, 82,
               112, 72, 16, 2, 0, 144, 0>>
           ) ==
             {:ok,
              %{
                sw1_result_code: 144,
                sw2_result_code: 0,
                read_result: <<152, 136, 3, 7, 0, 0, 16, 82, 112, 72>>
              }}
  end
end
