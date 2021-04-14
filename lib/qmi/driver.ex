defmodule QMI.Driver do
  use GenServer

  require Logger

  alias QMI.Message

  @type response :: {:ok, Message.t()} | {:error, Message.t() | :timeout}

  defmodule State do
    defstruct bridge: nil,
              caller: nil,
              device_path: nil,
              ref: nil,
              transactions: %{},
              last_ctl_transaction: 0,
              last_service_transaction: 256
  end

  @request_flags 0
  @request_type 0

  @type options() :: [device_path: Path.t(), caller: pid()]

  @spec start_link(options) :: GenServer.on_start()
  def start_link(options) do
    new_options = Keyword.put_new(options, :caller, self())
    GenServer.start_link(__MODULE__, new_options)
  end

  @doc """
  Send a message and return the response
  """
  @spec send(GenServer.server(), QMI.request(), keyword()) :: {:ok, binary()} | {:error, atom()}
  def send(server, request, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)

    GenServer.call(server, {:send, request, timeout}, timeout * 2)
  end

  @impl GenServer
  def init(opts) do
    state = struct(State, opts)
    {:ok, bridge} = DevBridge.start_link([])

    {:ok, %{state | bridge: bridge}, {:continue, :open}}
  end

  @impl GenServer
  def handle_continue(:open, state) do
    {:ok, ref} = DevBridge.open(state.bridge, state.device_path, [:read, :write])

    {:noreply, %{state | ref: ref}}
  end

  @impl GenServer
  def handle_call({:send, request, timeout}, from, state) do
    # FIXME get_client_id(request.service_id)
    client_id = 5
    {transaction, state} = do_request(request, client_id, state)
    timer = Process.send_after(self(), {:timeout, transaction}, timeout)
    {:noreply, %{state | transactions: Map.put(state.transactions, transaction, {from, timer})}}
  end

  @impl GenServer
  def handle_info({:timeout, transaction}, state) do
    state = pop_and_reply(state, transaction, {:error, :timeout})
    {:noreply, state}
  end

  def handle_info({:dev_bridge, ref, :read, data}, %{ref: ref} = state) do
    # TODO: Report indications somewhere?
    decoded = QMI.Message.decode(data)
    state = pop_and_reply(state, decoded)

    {:noreply, state}
  end

  def handle_info({:dev_bridge, ref, :error, err}, %{ref: ref} = state) do
    Logger.error("[QMI.Driver] #{state.dev} closed - #{inspect(err)}")
    {:noreply, state, {:continue, :open}}
  end

  defp do_request(request, client_id, state) do
    {transaction, state} = next_transaction(request.service_id, state)

    # Transaction needs to be sized based on control vs service message
    tran_size = if request.service_id == 0, do: 8, else: 16

    service_msg =
      make_service_msg(request.payload, request.service_id, client_id, transaction, tran_size)

    # Length needs to include the 2 length bytes as well
    len = IO.iodata_length(service_msg) + 2

    qmux_msg = [<<1, len::16-little>>, service_msg]

    {:ok, _len} = DevBridge.write(state.bridge, qmux_msg)

    {transaction, state}
  end

  defp make_service_msg(data, service, client_id, transaction, tran_size) do
    [
      <<@request_flags, service, client_id, @request_type, transaction::size(tran_size)-little>>,
      data
    ]
  end

  defp next_transaction(0, %{last_ctl_transaction: tran} = state) do
    # Control service transaction can only be 1 byte, which
    # is a max value of 255. Ensure we don't go over here
    # otherwise it will fail silently
    tran = if tran < 255, do: tran + 1, else: 1

    {tran, %{state | last_ctl_transaction: tran}}
  end

  defp next_transaction(_service, %{last_service_transaction: tran} = state) do
    # Service requests have 2-byte transaction IDs.
    # Use IDs from 256 to 65536 to avoid any confusion with control requests.
    tran = if tran < 65_535, do: tran + 1, else: 256

    {tran, %{state | last_service_transaction: tran}}
  end

  defp pop_and_reply(state, %Message{type: :indication} = msg) do
    Logger.debug("QMI Indication: #{inspect(msg)}")
    state
  end

  defp pop_and_reply(state, %Message{transaction: transaction} = msg) do
    result = if msg.code == :success, do: :ok, else: :error

    if result == :error do
      Logger.warn("#{inspect(msg)}")
    end

    pop_and_reply(state, transaction, {result, msg.service_msg_bin})
  end

  defp pop_and_reply(state, transaction, reply) do
    {meta, transactions} = Map.pop(state.transactions, transaction)

    case meta do
      {from, timer} ->
        _ = Process.cancel_timer(timer)
        GenServer.reply(from, reply)

      _ ->
        :ignore
    end

    %{state | transactions: transactions}
  end
end
