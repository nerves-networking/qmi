defmodule QMI.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: QMI.Supervisor]

    children = []

    Supervisor.start_link(children, opts)
  end
end
