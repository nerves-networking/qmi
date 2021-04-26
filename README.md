# QMI

Qualcomm MSM Interface in Elixir

Primarily referenced from [Telit LM940 QMI Command Reference Guide](assets/telit_qmi_guide.pdf) and the [`libqmi` source](https://gitlab.freedesktop.org/mobile-broadband/libqmi/-/tree/master)

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
    {:qmi, "~> 0.3.0"}
  ]
end
```
