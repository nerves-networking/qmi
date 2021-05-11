# QMI

Qualcomm MSM Interface in Elixir

## Usage

```
iex> QMI.configure_linux("wwan0")
iex> {:ok, qmi} = QMI.start_link(ifname: "wwan0")
iex> QMI.WirelessData.start_network_interface(qmi, apn: "super")
:ok
iex> QMI.NetworkAccess.get_signal_strength(qmi)
{:ok, %{rssi_reports: [%{radio: :lte, rssi: -74}]}}
```

If you are using Linux you will need to call `QMI.configure_linux/1` before
bring the interface up.

## Install

```elixir
def deps do
  [
    {:qmi, "~> 0.3.1"}
  ]
end
```

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