# QMI

[![Hex version](https://img.shields.io/hexpm/v/qmi.svg "Hex version")](https://hex.pm/packages/qmi)
[![API docs](https://img.shields.io/hexpm/v/qmi.svg?label=hexdocs "API docs")](https://hexdocs.pm/qmi/QMI.html)
[![CircleCI](https://circleci.com/gh/smartrent/qmi.svg?style=svg)](https://circleci.com/gh/smartrent/qmi)

Qualcomm MSM Interface in Elixir

This library lets you send and receive messages from a QMI-enabled cellular
modem. It is intended for use with `vintage_net_qmi` and most users will
want to use `VintageNet` to configure a cellular modem than to use this
library directly.

## Usage

First, start a `QMI.Supervisor` in the supervision tree of your choosing
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

If you are using Linux you will need to call `QMI.configure_linux/1` before
bring the interface up.

## License

Copyright (C) 2021 SmartRent

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.