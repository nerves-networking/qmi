defmodule DevBridge do
  @moduledoc """
  Interact with special files in `/dev` without messing up the BEAM*

  *Well, you can still mess it up and probably in even better ways, but this
  module saves you from the blocking and other odd behavior from device files
  that makes Erlang refuse to open the files.
  """
  use GenServer
  require Logger

  @type options() :: [
          name: GenServer.name(),
          read_buffer_size: non_neg_integer(),
          write_buffer_size: non_neg_integer()
        ]

  @default_options [mode: [:write], read_buffer_size: 4096, write_buffer_size: 4096]

  @cmd_write 1
  # @cmd_ioctl 2
  # @cmd_position 3
  @notif_reply 0
  @notif_data 1
  @notif_error 2

  @doc """
  Start the device file handling GenServer.
  """
  @spec start_link(options()) :: GenServer.on_start()
  def start_link(init_args) do
    options = Keyword.take(init_args, [:name])
    GenServer.start_link(__MODULE__, init_args, options)
  end

  @doc """
  Open the device file

  On success a reference is returned that uniquely identifies this opening of
  the device file. I.e., if you close and re-open the device file, you'll get a
  different reference.

  The process that calls `open/2` will be sent messages when things happen on
  the device:

  * `{:dev_bridge, ref, :read, data}` - sent when bytes are received on the
    device file if it was opened with the `:read` option
  * `{:dev_bridge, ref, :error, posix}` - sent when an error occurs that causes
    the device file to be closed.
  """
  @spec open(GenServer.server(), Path.t(), [File.mode()], options()) :: {:ok, reference()}
  def open(server, path, modes, opts \\ []) when is_list(modes) and is_list(opts) do
    GenServer.call(server, {:open, path, modes, opts})
  end

  @doc """
  Close the device file

  Manually clone a previously opened device file. It is unnecessary to call
  this unless the timing of the close operation is important. Files will be
  closed automatically on error, when the `GenServer` stops and when `open/4`
  is called.
  """
  @spec close(GenServer.server()) :: :ok
  def close(server) do
    GenServer.call(server, :close)
  end

  @doc """
  Write the specified bytes to the device

  Depending on the device, it might not be the case that all bytes are written.
  This could be how the device file works, so it's not an error.  If it's
  important that all bytes are returned, the caller should repeated call this
  function.

  On success, the number of bytes written is returned.
  """
  @spec write(GenServer.server(), iodata()) :: {:ok, non_neg_integer()}
  def write(server, data) do
    GenServer.call(server, {:write, data})
  end

  @doc """
  Set the position in the device file

  TBD
  """
  @spec position(GenServer.server(), :file.location()) :: :ok
  def position(server, location) do
    GenServer.call(server, {:position, location})
  end

  @doc """
  Call an ioctl on the device

  TBD
  """
  @spec ioctl(GenServer.server(), non_neg_integer(), binary()) :: {:ok, binary()}
  def ioctl(server, num, to_send) do
    GenServer.call(server, {:ioctl, num, to_send})
  end

  @impl GenServer
  def init(init_args) do
    {:ok,
     %{
       init_args: Keyword.merge(@default_options, init_args),
       port: nil,
       ref: nil,
       notification_pid: nil
     }}
  end

  @impl GenServer
  def handle_call({:open, path, modes, opts}, from, state) do
    all_opts = Keyword.merge(state.init_args, opts)

    close_port(state.port)
    port = open_port(path, modes, all_opts)
    ref = make_ref()
    {caller_pid, _caller_ref} = from

    {:reply, {:ok, ref}, %{state | port: port, ref: ref, notification_pid: caller_pid}}
  end

  def handle_call(:close, _from, state) do
    close_port(state.port)

    {:reply, :error, %{state | port: nil, ref: nil}}
  end

  def handle_call({:write, data}, from, state) do
    call_port(state.port, @cmd_write, data, from)
    {:noreply, state}
  end

  def handle_call({:position, _location}, _from, state) do
    {:reply, :error, state}
  end

  @impl GenServer
  def handle_info({port, {:data, data}}, %{port: port} = state) do
    new_state = handle_data(data, state)

    {:noreply, new_state}
  end

  def handle_info({port, {:exit_status, _status}}, %{port: port} = state) do
    if state.ref do
      send(state.notification_pid, {:dev_bridge, state.ref, :closed})
    end

    {:noreply, %{state | port: nil, ref: nil}}
  end

  defp handle_data(
         <<@notif_reply, from_len, from_bits::binary-size(from_len), rc::signed-16,
           posix::binary>>,
         state
       ) do
    from = :erlang.binary_to_term(from_bits)
    result = if rc < 0, do: {:error, :erlang.binary_to_atom(posix)}, else: {:ok, rc}

    GenServer.reply(from, result)
    state
  end

  defp handle_data(
         <<@notif_data, data::binary>>,
         state
       ) do
    send(state.notification_pid, {:dev_bridge, state.ref, :read, data})
    state
  end

  defp handle_data(
         <<@notif_error, posix::binary>>,
         state
       ) do
    send(state.notification_pid, {:dev_bridge, state.ref, :error, :erlang.binary_to_atom(posix)})
    state
  end

  defp open_port(path, modes, opts) do
    Port.open({:spawn_executable, executable()}, [
      {:args, opts_to_args(path, modes, opts)},
      {:packet, 2},
      :use_stdio,
      :binary,
      :exit_status
    ])
  end

  defp close_port(nil), do: :ok

  defp close_port(port) do
    Port.close(port)
  end

  defp call_port(port, command, data, from) when port != nil do
    from_bits = :erlang.term_to_binary(from)
    message = [command, byte_size(from_bits), from_bits, data]

    Port.command(port, message)
  end

  defp executable() do
    Application.app_dir(:qmi, ["priv", "dev_bridge"])
  end

  defp opts_to_args(path, modes, opts) do
    [
      path,
      read_buffer_size_arg(modes, opts),
      write_buffer_size_arg(modes, opts)
    ]
  end

  defp read_buffer_size_arg(modes, opts) do
    size = opts[:read_buffer_size]

    if Enum.member?(modes, :read) and size > 0 do
      Integer.to_string(size)
    else
      "0"
    end
  end

  defp write_buffer_size_arg(modes, opts) do
    size = opts[:write_buffer_size]

    if Enum.member?(modes, :write) and size > 0 do
      Integer.to_string(size)
    else
      "0"
    end
  end
end
