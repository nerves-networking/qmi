defmodule QMI.WirelessData.GetPacketServiceStatusResp do
  @moduledoc """
  Response to a request querying the connection status

  If the connection is `:connected` it does not mean that the IP address has
  been assigned, but only means that IP configuration can commence.
  """

  @type connection_status() :: :disconnected | :connected | :suspended | :authenticating

  @type t() :: %__MODULE__{
          connection_status: connection_status()
        }

  defstruct connection_status: nil

  defimpl QMI.Response do
    def parse_tlvs(response, <<0x01, 0x01::little-16, conn_status>>) do
      %QMI.WirelessData.GetPacketServiceStatusResp{
        response
        | connection_status: connection_status(conn_status)
      }
    end

    defp connection_status(conn_status) do
      case conn_status do
        1 -> :disconnected
        2 -> :connected
        3 -> :suspended
        4 -> :authenticating
      end
    end
  end
end
