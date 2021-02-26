defmodule QMI.Driver do
  use GenServer

  require Logger

  alias QMI.Message

  @type response :: {:ok, Message.t()} | {:error, Message.t() | :timeout}

  defmodule State do
    defstruct bridge: nil,
              caller: nil,
              dev: "/dev/cdc-wdm0",
              ref: nil,
              transactions: %{},
              last_ctl_transaction: 0,
              last_service_transaction: 0
  end

  @request_flags 0
  @request_type 0

  @spec start_link(QMI.device()) :: GenServer.on_start()
  def start_link(dev) do
    GenServer.start_link(__MODULE__, [dev: dev, caller: self()], name: via_name(dev))
  end

  defp via_name(driver_pid) when is_pid(driver_pid), do: driver_pid

  defp via_name(device) do
    {:via, Registry, {QMI.Driver.Registry, device}}
  end

  @spec request(QMI.device() | pid(), binary(), QMI.control_point(), non_neg_integer()) ::
          response()
  def request(device, msg, client, timeout \\ 5_000) do
    ##
    # Responses will come async so we handle the timeout to the request
    # manually with timers after submitting the request. To ensure
    # GenServer gives us enough time, we'll significantly bump it here
    gen_timeout = timeout * 2
    GenServer.call(via_name(device), {:request, msg, client, timeout}, gen_timeout)
  end

  @spec request_async(QMI.device() | pid(), binary(), QMI.control_point()) :: :ok
  def request_async(device, msg, client) do
    GenServer.cast(via_name(device), {:request, msg, client})
  end

  @impl GenServer
  def init(opts) do
    state = struct(State, opts)
    {:ok, bridge} = DevBridge.start_link(name: :"#{state.dev}-bridge")

    {:ok, %{state | bridge: bridge}, {:continue, :open}}
  end

  @impl GenServer
  def handle_call({:request, msg, client, timeout}, from, state) do
    {transaction, state} = do_request(msg, client, state)
    timer = Process.send_after(self(), {:timeout, transaction}, timeout)
    {:noreply, %{state | transactions: Map.put(state.transactions, transaction, {from, timer})}}
  end

  @impl GenServer
  def handle_cast({:request, msg, client}, state) do
    {_transaction, state} = do_request(msg, client, state)
    {:noreply, state}
  end

  @impl GenServer
  def handle_continue(:open, state) do
    require Logger

    Logger.warn("#{inspect(state)}")
    {:ok, ref} = DevBridge.open(state.bridge, state.dev, [:read, :write])

    {:noreply, %{state | ref: ref}}
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

  defp do_request(msg, {service, client_id}, state) do
    {transaction, state} = next_transaction(service, state)

    # Transaction needs to be sized based on control vs service message
    tran_size = if service == 0, do: 8, else: 16

    service_msg =
      <<@request_flags, service, client_id, @request_type, transaction::size(tran_size)-little>> <>
        msg

    # Length needs to include the 2 length bytes as well
    len = byte_size(service_msg) + 2

    qmux_msg = <<1, len::16-little>> <> service_msg

    {:ok, _len} = DevBridge.write(state.bridge, qmux_msg)

    {transaction, state}
  end

  defp next_transaction(0, %{last_ctl_transaction: tran} = state) do
    # Control service transaction can only be 1 byte, which
    # is a max value of 255. Ensure we don't go over here
    # otherwise it will fail silently
    tran = if tran < 255, do: tran + 1, else: 1

    {tran, %{state | last_ctl_transaction: tran}}
  end

  defp next_transaction(_service, %{last_service_transaction: tran} = state) do
    # max num for 2 bytes is 65535
    tran = if tran < 65_535, do: tran + 1, else: 1

    # Avoid potential collision with control transactions
    tran = if tran == state.last_ctl_transaction, do: tran + 1, else: tran

    {tran, %{state | last_service_transaction: tran}}
  end

  defp pop_and_reply(state, %Message{type: :indication} = msg) do
    send(state.caller, {QMI, msg})
    state
  end

  defp pop_and_reply(state, %Message{transaction: transaction} = msg) do
    result = if msg.code == :success, do: :ok, else: :error
    pop_and_reply(state, transaction, {result, msg})
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
