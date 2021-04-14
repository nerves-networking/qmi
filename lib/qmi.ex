defmodule QMI do
  use GenServer

  @moduledoc """

  Example use:

  ```elixir
  iex> QMI.configure_linux()
  :ok
  iex> {:ok, qmi} = QMI.start_link(device_path: "/dev/cdc-wm0")
  iex> QMI.WirelessData.start_network_interface(qmi, apn: "super")
  :ok
  iex> QMI.NetworkAccess.get_signal_strength(qmi)
  %{rssis: [%{radio: :lte, rssi: -74}]}
  """
  alias QMI.{ControlPointCache, Driver}

  @type request() :: %{
          service_id: non_neg_integer(),
          payload: iodata(),
          decode: (binary() -> map())
        }

  @typedoc """
  QMI GenServer options

  * `:device_path` - the path to the QMI control device. i.e. `"/dev/cdc-wdm0"`
  * `:name` - an optional name for this GenServer
  """
  @type options() :: [device_path: Path.t(), name: atom()]

  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    Keyword.has_key?(options, :device_path) || raise RuntimeError, "Must pass :device_path"

    gen_server_options = Keyword.take(options, [:name])
    GenServer.start_link(__MODULE__, options, gen_server_options)
  end

  @impl GenServer
  def init(init_args) do
    driver = Driver.start_link(init_args)
    control_point_cache = ControlPointCache.start_link(init_args)

    {:ok, %{driver: driver, control_point_cache: control_point_cache}}
  end
end
