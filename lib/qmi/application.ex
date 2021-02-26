defmodule QMI.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    opts = [strategy: :one_for_one, name: QMI.Supervisor]

    children = [
      {Registry, keys: :unique, name: QMI.Driver.Registry},
      {QMI.Driver.Supervisor, []}
    ]

    Supervisor.start_link(children, opts)
  end
end
