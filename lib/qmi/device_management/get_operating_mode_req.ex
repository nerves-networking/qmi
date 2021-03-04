defmodule QMI.DeviceManagement.GetOperatingModeReq do
  @moduledoc """

  """

  @type t() :: %__MODULE__{}

  defstruct []

  defimpl QMI.Request do
    @get_operating_state_mode 0x002D

    def encode(_message) do
      <<@get_operating_state_mode::16-little, 0x00, 0x00, 0x00>>
    end
  end
end
