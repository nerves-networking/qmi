# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.MessageTest do
  use ExUnit.Case, async: true

  alias QMI.Message

  @control_service_id 0x00
  @network_access_service_id 0x03

  describe "control service messages" do
    test "response" do
      control_message_response = make_message(@control_service_id, <<0x01>>, 0x01, :success)

      expected_message = %{
        type: :response,
        transaction_id: 0x01,
        service_id: 0x00,
        code: :success,
        error: :none,
        message: make_service_message(:success)
      }

      assert Message.decode(control_message_response) == {:ok, expected_message}
    end

    test "indication" do
      control_message_indication = make_message(@control_service_id, <<0x01>>, 0x02, :success)

      expected_message = %{
        type: :indication,
        transaction_id: 0x01,
        service_id: 0x00,
        message: <<0x10, 0x00, 0x00, 0x00, 0x02, 0x04, 0x00, 0x00, 0x00, 0x00, 0x00>>
      }

      assert Message.decode(control_message_indication) == {:ok, expected_message}
    end

    test "response error" do
      control_message_error = make_message(@control_service_id, <<0x01>>, 0x01, :error)

      expected_message = %{
        type: :response,
        transaction_id: 0x01,
        service_id: 0x00,
        code: :failure,
        error: :no_permission,
        message: make_service_message(:error)
      }

      assert Message.decode(control_message_error) == {:ok, expected_message}
    end
  end

  describe "service messages" do
    test "response" do
      network_access_message_response =
        make_message(@network_access_service_id, <<0x01::16-little>>, 0x02, :success)

      expected_message = %{
        type: :response,
        transaction_id: 0x01,
        service_id: 0x03,
        code: :success,
        error: :none,
        message: make_service_message(:success)
      }

      assert Message.decode(network_access_message_response) == {:ok, expected_message}
    end

    test "error" do
      network_access_message_response =
        make_message(@network_access_service_id, <<0x01::16-little>>, 0x02, :error)

      expected_message = %{
        type: :response,
        transaction_id: 0x01,
        service_id: 0x03,
        code: :failure,
        error: :no_permission,
        message: make_service_message(:error)
      }

      assert Message.decode(network_access_message_response) == {:ok, expected_message}
    end
  end

  defp make_message(service_id, transaction_id, type, success_or_error) do
    <<0x01, 0x00::size(16), 0x00, service_id, 0x00, type, transaction_id::binary,
      make_service_message(success_or_error)::binary>>
  end

  defp make_service_message(:success) do
    <<0x10::16-little, 0x00::16-little, 0x02, 0x04::16-little, 0x00::16-little, 0x00::16-little>>
  end

  defp make_service_message(:error) do
    <<0x10::16-little, 0x00::16-little, 0x02, 0x04::16-little, 0x01::16-little, 0x73::16-little>>
  end
end
