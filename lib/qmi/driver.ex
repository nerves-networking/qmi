defmodule QMI.Driver do
  @moduledoc false

  use GenServer

  require Logger

  defmodule State do
    @moduledoc false

    defstruct bridge: nil,
              device_path: nil,
              ref: nil,
              transactions: %{},
              last_ctl_transaction: 0,
              last_service_transaction: 256
  end

  @request_flags 0
  @request_type 0

  @type options() :: [name: module(), device_path: Path.t()]

  @spec start_link(options) :: GenServer.on_start()
  def start_link(init_args) do
    qmi = Keyword.fetch!(init_args, :name)

    GenServer.start_link(__MODULE__, init_args, name: name(qmi))
  end

  defp name(qmi) do
    Module.concat(qmi, Driver)
  end

  @doc """
  Send a message and return the response
  """
  @spec call(GenServer.server(), non_neg_integer(), QMI.request(), keyword()) ::
          :ok | {:ok, any()} | {:error, atom()}
  def call(qmi, client_id, request, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)

    GenServer.call(name(qmi), {:call, client_id, request, timeout}, timeout * 2)
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
  def handle_call({:call, client_id, request, timeout}, from, state) do
    {transaction, state} = do_request(request, client_id, state)
    timer = Process.send_after(self(), {:timeout, transaction}, timeout)

    {:noreply,
     %{state | transactions: Map.put(state.transactions, transaction, {from, request, timer})}}
  end

  @impl GenServer
  def handle_info({:timeout, transaction_id}, state) do
    {:noreply, fail_transaction_id(state, transaction_id, :timeout)}
  end

  def handle_info({:dev_bridge, ref, :read, data}, %{ref: ref} = state) do
    case QMI.Message.decode(data) do
      {:ok, message} ->
        handle_report(message, state)

      {:error, _reason} ->
        Logger.warn(
          "[QMI.Driver] #{state.device_path} invalid message from QMI: #{inspect(data)}"
        )

        {:noreply, state}
    end
  end

  def handle_info({:dev_bridge, ref, :error, err}, %{ref: ref} = state) do
    Logger.error("[QMI.Driver] #{state.device_path} - Error: #{inspect(err)}")
    {:noreply, state}
  end

  def handle_info({:dev_bridge, ref, :closed}, %{ref: ref} = state) do
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

  defp handle_report(%{type: :indication} = msg, state) do
    case QMI.Codec.Indication.parse(msg) do
      {:ok, info} ->
        Logger.warn("QMI: Ignoring indication: #{inspect(info, limit: :infinity)}")

      {:error, _} ->
        Logger.warn("QMI: Unknown indication: #{inspect(msg, limit: :infinity)}")
    end

    {:noreply, state}
  end

  defp handle_report(%{transaction_id: transaction_id, code: :success} = msg, state) do
    {{from, request, timer}, transactions} = Map.pop(state.transactions, transaction_id)
    _ = Process.cancel_timer(timer)
    result = msg.message |> request.decode.()

    if match?({:error, _reason}, result) do
      Logger.warn(
        "QMI: Error decoding response to #{inspect(request)}: message was #{
          inspect(msg.message, limit: :infinity)
        }"
      )
    end

    GenServer.reply(from, result)
    {:noreply, %{state | transactions: transactions}}
  end

  defp handle_report(%{transaction_id: transaction_id, code: error}, state) do
    {:noreply, fail_transaction_id(state, transaction_id, error)}
  end

  defp fail_transaction_id(state, transaction_id, error) do
    {{from, _request, timer}, transactions} = Map.pop(state.transactions, transaction_id)
    _ = Process.cancel_timer(timer)
    GenServer.reply(from, {:error, error})
    %{state | transactions: transactions}
  end
end
