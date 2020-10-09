# Qmi

Quick test implementing Qualcomm MSM Interface in Elixir

## Usage

Currently only fetching signal strength supported

TODO: Need to implement sending message to dev FD

```elixir
QMI.get_signal_strength("/dev/cdc-wdm0")
```
