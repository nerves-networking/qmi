defmodule QMI.Driver.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  @doc """
  Start the driver supervisor
  """
  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Start a driver
  """
  @spec start_driver(String.t()) :: {:ok, pid()} | {:error, :max_children | term()} | :ignore
  def start_driver(device) do
    spec = QMI.Driver.child_spec(device)

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, _pid} = ok -> ok
      {:error, {:already_started, pid}} -> {:ok, pid}
      {:error, _reason} = error -> error
    end
  end

  @impl DynamicSupervisor
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
