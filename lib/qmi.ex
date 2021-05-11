defmodule QMI do
  @moduledoc """
  Qualcomm MSM Interface in Elixir

  This module lets you send and receive messages from a QMI-enabled cellular
  modem.

  To use it, start a `QMI.Supervisor` in the supervision tree of your choosing
  and pass it a name and interface. After that, use the service modules to send
  it messages. For example:

  ```elixir
  # In your application's supervision tree
  children = [
    #... other children ...
    {QMI.Supervisor, ifname: "wwan0", name: MyApp.QMI}
    #... other children ...
  ]

  # Later on
  iex> QMI.WirelessData.start_network_interface(MyApp.QMI, apn: "super")
  :ok

  iex> QMI.NetworkAccess.get_signal_strength(MyApp.QMI)
  {:ok, %{rssi_reports: [%{radio: :lte, rssi: -74}]}}
  ```
  """

  @typedoc """
  The name passed to QMI.Supervisor
  """
  @type name() :: atom()

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
  Send a request over QMI and return the response

  NOTE: the QMI name parameter is second to facilitate piping
  """
  @spec call(request(), name()) :: :ok | {:ok, any()} | {:error, atom()}
  def call(request, qmi) do
    with {:ok, client_id} <- QMI.ClientIDCache.get_client_id(qmi, request.service_id) do
      QMI.Driver.call(qmi, client_id, request)
    end
  end
end
