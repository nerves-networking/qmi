# SPDX-FileCopyrightText: 2021 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Matt Ludwigs
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule QMI.Supervisor do
  @moduledoc """
  Main supervisor for QMI processes
  """

  use Supervisor

  @typedoc """
  QMI Supervisor options

  * `:ifname` - the network interface name. i.e. `"wwan0"`
  * `:device_path` - the path to the QMI control device. Defaults to `"/dev/cdc-wdm<index>"`
  where `index` matches the `ifname` index.
  * `:name` - an optional name for this GenServer
  * `:indication_callback` - a function that is ran when an indication is
  received from QMI.
  """
  @type options() :: [
          ifname: String.t(),
          device_path: Path.t(),
          name: atom(),
          indication_callback: QMI.indication_callback_fun()
        ]

  @doc """
  Start the supervisor

  The `:name` option is required and will be the QMI supervisor process. Pass
  this name to all functions that have a `qmi` parameter.
  """
  @spec start_link(options()) :: Supervisor.on_start()
  def start_link(options) do
    real_options = derive_options(options)
    name = Keyword.fetch!(real_options, :name)

    Supervisor.start_link(__MODULE__, real_options, name: name)
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
