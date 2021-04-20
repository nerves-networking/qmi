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

  use GenServer

  alias QMI.{Codec, Driver}

  @type t() :: GenServer.server()

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
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(options) do
    real_options = derive_options(options)

    gen_server_options = Keyword.take(real_options, [:name])
    GenServer.start_link(__MODULE__, real_options, gen_server_options)
  end

  @doc """
  Send a request over QMI and return the response

  NOTE: the server parameter is second to facilitate piping
  """
  @spec call(request(), GenServer.server()) :: :ok | {:ok, any()} | {:error, atom()}
  def call(request, server) do
    get_call_function(server, request.service_id).(request)
  end

  # Helper function for getting everything that's needed to run the "call" in
  # the process context calling `call/2`.
  defp get_call_function(server, service_id) do
    GenServer.call(server, {:get_call_function, service_id})
  end

  @impl GenServer
  def init(init_args) do
    {:ok, driver} = Driver.start_link(init_args)

    {:ok, %{driver: driver, client_ids: %{}}}
  end

  @impl GenServer
  def handle_call({:get_call_function, service_id}, _from, state) do
    case state.client_ids[service_id] do
      nil ->
        request = Codec.Control.get_client_id(service_id)
        {:ok, client_id} = Driver.call(state.driver, 0, request)
        new_state = %{state | client_ids: Map.put(state.client_ids, service_id, client_id)}
        {:reply, fn request -> Driver.call(state.driver, client_id, request) end, new_state}

      client_id ->
        {:reply, fn request -> Driver.call(state.driver, client_id, request) end, state}
    end
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
