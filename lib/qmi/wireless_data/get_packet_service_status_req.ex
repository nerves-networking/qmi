defmodule QMI.WirelessData.GetPacketServiceStatusReq do
  @moduledoc """
  Request to query the packet data connection provided by a wireless device
  """

  @type t() :: %__MODULE__{}

  defstruct []

  defimpl QMI.Request do
    def encode(_request) do
      <<0x0022::little-16, 0, 0>>
    end
  end
end
