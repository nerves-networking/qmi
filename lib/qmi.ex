defmodule QMI do
  @moduledoc """
  Send QMI messages to a QMI device

  Example use:

  ```elixir
  iex> {:ok, qmi} = QMI.start_link(ifname: "wwan0")
  iex> QMI.WirelessData.start_network_interface(qmi, apn: "super")
  :ok
  iex> QMI.NetworkAccess.get_signal_strength(qmi)
  {:ok, %{rssi_reports: [%{radio: :lte, rssi: -74}]}}
  ```

  Starting QMI in a supervision tree

  ```elixir

  children = [
    #... other children ...
    {QMI, ifname: "wwan0", name: MyApp.QMI}
    #... other children ...
  ]

  # Later in your app

  QMI.NetworkAccess.get_signal_strength(MyApp.QMI)
  ```
  """
  use Supervisor

  @type t() :: atom()

  @typedoc """
  Structure that contains information about how to handle a QMI service message

  * `:service_id` - which service this request is for
  * `:payload` - iodata of the message being sent
  * `:decode` - a function that will be used to decode the incoming response
  """
  @type request() :: %{
          service_id: non_neg_integer(),
          payload: iodata(),
          decode: (binary() -> {:ok, any()} | {:error, atom()})
        }

  @typedoc """
  QMI GenServer options

  * `:ifname` - the network interface name. i.e. `"wwan0"`
  * `:device_path` - the path to the QMI control device. Defaults to `"/dev/cdc-wdm<index>"`
  where `index` matches the `ifname` index.
  * `:name` - an optional name for this GenServer
  """
  @type options() :: [ifname: String.t(), device_path: Path.t(), name: atom()]

  @doc """
  Configure the framing when using linux

  This should be called once the device appears and before an attempt is made to
  connect to the network.
  """
  @spec configure_linux(String.t()) :: :ok
  def configure_linux(ifname) do
    # This might not be true for all modems as some support 802.3 IP framing,
    # however, on the EC25 supports raw IP framing. This feature can be detected
    # and is probably a better solution that just forcing the raw IP framing.
    File.write!("/sys/class/net/#{ifname}/qmi/raw_ip", "Y")
  end

  @doc """
  Start the server

  The `:name` option is required and will be the QMI supervisor process. Pass
  this name to all functions that have a `qmi` parameter.
  """
  @spec start_link(options()) :: Supervisor.on_start()
  def start_link(options) do
    real_options = derive_options(options)
    name = Keyword.fetch!(real_options, :name)

    Supervisor.start_link(__MODULE__, real_options, name: name)
  end

  @doc """
  Send a request over QMI and return the response

  NOTE: the server parameter is second to facilitate piping
  """
  @spec call(request(), t()) :: :ok | {:ok, any()} | {:error, atom()}
  def call(request, qmi) do
    with {:ok, client_id} <- QMI.ClientIDCache.get_client_id(qmi, request.service_id) do
      QMI.Driver.call(qmi, client_id, request)
    end
  end

  @impl Supervisor
  def init(init_args) do
    children = [
      {QMI.ClientIDCache, init_args},
      {QMI.Driver, init_args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp derive_options(options) do
    ifname = Keyword.fetch!(options, :ifname)
    Keyword.put_new_lazy(options, :device_path, fn -> ifname_to_control_path(ifname) end)
  end

  defp ifname_to_control_path("wwan" <> index) do
    "/dev/cdc-wdm" <> index
  end

  defp ifname_to_control_path(other) do
    raise RuntimeError,
          "Don't know how to derive control device from #{other}. Pass in a :device_path"
  end
end
