defmodule QMI.Service do
  @moduledoc File.read!("README.md")
             |> String.split(~r/<!-- ServiceDOC !-->/)
             |> Enum.drop(1)
             |> Enum.join("\n")

  alias QMI.Message
  @callback decode_response_tlvs(Message.t()) :: Message.t()

  defmacro __using__(opts) do
    id =
      Keyword.get_lazy(opts, :id, fn ->
        raise("The :id option must be specified when using QMI.id")
      end)

    unless is_integer(id) do
      raise("QMI.Service :id must be an integer")
    end

    quote location: :keep, bind_quoted: [id: id] do
      @behaviour QMI.Service

      @id id

      def id(), do: @id

      @doc """
      Helper to get control point for this service

      Control Points are required to making requests for a service
      function. See QMI.Service.Control.get_control_point/2
      """
      defdelegate get_control_point(driver, service \\ @id), to: QMI.Service.Control
    end
  end
end
