# Qmi

Qualcomm MSM Interface in Elixir

Primarily referenced from [Telit LM940 QMI Command Reference Guide](assets/telit_qmi_guide.pdf) and the [`libqmi` source](https://gitlab.freedesktop.org/mobile-broadband/libqmi/-/tree/master)

## Usage
<!-- CPDOC !-->
All requests must be communicated through the QMI driver.

When making requests to a service, a client must be allocated
first and that client ID must be used in subsequent requests.

This function makes the call to allocate a client for the specified
service and then returns the control point to be used in requests,
formated as a `{service, client_id}` tuple.

When all desired requests are completed, the client must be
released with `release_control_point/2`.

```elixir
# Make sure the driver is started. This is used in all requests
{:ok, driver} = QMI.Driver.start_link("/dev/cdc-wdm0")

# Get a control point for NetworkAccess service
cp = QMI.Service.Control.get_control_point(driver, 3)

QMI.Service.NetworkAccess.get_signal_strength(driver, cp)
# => %QMI.Message{}

# When finished, Control point must be released
QMI.Server.Control.release_control_point(driver, cp)
```
<!-- CPDOC !-->

## Implementing new service requests

<!-- ServiceDOC !-->
Use the `use QMI.Service` macro when creating a new service which will
implement the `QMI.Service` behaviour and a few helper functions.

Under the hood, `QMI.Driver` formats messages as the expected QMUX format with
a QMUX header, service header, and the adjoining service message. When
implementing new services requests, you'll only need to worry about the
specific message structure when sending to the driver.

The message structure is little-endian and structured as:

| Message ID | Message Length | Mandatory TLVs (Type-Length-Value)
| --- | --- | --- |
| 2 bytes | 2 bytes | variable |

For example, the `QMI_CTL_GET_CLIENT_ID_REQ` is type `0x22` and has one
mandatory TLV of type `1`, `length` 1 (as 2 bytes), and the service value to request
a client for. Once put together, the message should be 4 bytes.
The resulting message looks like:

```elixir
msg_id = 0x22
msg_len = 4
type = 1
len = 1 
val = 3 # Network Access Service

bin = <<msg_id::little-16, msg_len::little-16, type, len::little-16, val>>
# => <<34, 0, 4, 0, 1, 1, 0, 3>>

# You can then send this to the driver (after obtaining a control point)
QMI.Driver.request(driver, bin, control_point)
```
<!-- ServiceDOC !-->

## Reverse engineering qmicli

If you want to see more in action, you can place `strace` on the device and
issue requests with `qmicli` and reviewing the subsequent output.

command with defaults:

```sh
cmd "/root/strace -o /root/output-hex qmicli -d /dev/cdc-wdm0 --device-open-qmi --nas-get-signal-strength"
```

command with hex output:

```sh
cmd "/root/strace -x -o /root/output-hex qmicli -d /dev/cdc-wdm0 --device-open-qmi --nas-get-signal-strength"
```
