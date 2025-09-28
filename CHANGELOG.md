<!--
  SPDX-License-Identifier: CC0-1.0
  SPDX-FileCopyrightText: None
-->

<!-- markdownlint-disable-file MD024 -->
# Changelog

This project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v0.10.2] - 2025-09-28

* Support Get Current Settings for getting the MTU. Thanks to @joserp93

## [v0.10.1] - 2025-06-09

* Update licensing and copyright for REUSE compliance
* Ignore invalid emergency access barred values that were seen in the wild

## [v0.10.0] - 2024-07-25

## Changed

* Trim invalid characters from `QMI_NAS_GET_SYS_INFO` MCC and MNC values

## [v0.9.0] - 2024-07-25

## Changed

* Require Elixir 1.14 and OTP 25

### Added

* Add `QMI_NAS_GET_SYS_INFO` and `QMI_NAS_GET_CELL_LOCATION_INFO`

## [v0.8.6] - 2023-09-08

## Changed

* Fix Elixir and C compilation warnings
* Improved specs

## [v0.8.5] - 2023-04-01

### Fixes

* Fixed incorrect enum value for serving system registration state reports. This
  could cause crashes if the value 3 (registration denied) was received.
* Fixed spelling of `:fw_update_discontinuous_frame`

## [v0.8.4] - 2022-04-25

### Added

* `QMI.WirelessData.modify_profile_settings/3` function
* Can pass 3GPP profile index to `QMI.WirelessData.start_network_interface/2`
* `:roaming_preference` option to
  `QMI.NetworkAccess.set_system_selection_preference/2`
* `QMI.Codec.WirelessData.modify_profile_settings/2` function
* `QMI.Codec.WirelessData.profile_setting()` type
* `QMI.Codec.WirelessData.profile_type()` type
* `:profile_3gpp_index` option
  `QMI.Codec.WirelessData.start_network_interface_opt()` type

## [v0.8.3] - 2022-02-10

### Added

Support for getting and setting modem operating mode and support for getting
and setting configuration for the modem's radio technology preference.

* `QMI.DeviceManagement.get_operating_mode/1` (@jjcarstens)
* `QMI.DeviceManagement.set_operating_mode/2` (@jjcarstens)
* `QMI.Codec.DeviceManagement.get_operating_mode/0` (@jjcarstens)
* `QMI.Codec.DeviceManagement.set_operating_mode/1` (@jjcarstens)
* `QMI.NetworkAccess.get_system_selection_preference/1`
* `QMI.NetworkAccess.set_system_selection_preference/2`
* `QMI.Codec.NetworkAccess.get_system_selection_preference/0`
* `QMI.Codec.NetworkAccess.set_system_selection_preference/1`


## [v0.8.2] - 2021-10-21

### Added

* Basic parsing of the NAS operator name indication

## [v0.8.1] - 2021-09-21

### Fixes

* Wrong value for TX/RX stats that have no data to report yet
* Actually parse TX/RX packets drop count

## [v0.8.0] - 2021-09-21

This release breaks the type `QMI.Codec.NetworkAccess.rf_band_information()` by
changing the `:band` field to a string for a more user friendly description of
the current active band.

### Changed

* Changed `QMI.Codec.NetworkAccess.rf_band_information()` field `:band` from
  `integer()` to `binary()`

## [v0.7.1] - 2021-09-16

### Added

* `QMI.NetworkAccess.get_rf_band_info/1` to get band and channel information
* `QMI.WirelessData.set_event_report/2` to configure the wireless data service
  to report transmit and receive stats
* Parsing for wireless data service's event report indication
* `QMI.Codec.WirelessData.set_event_report/1`
* `QMI.Codec.NetworkAccess.get_rf_band_info/0`

### Changed

* `QMI.request()` decode function type now allows returning `:ok` for request
  that who's response does not contain any information.

## [v0.7.0] - 2021-09-02

### Changed

* Changed `QMI.Codec.NetworkAccess.serving_system_indication()` time zone
  fields to match Elixir's `Calendar` module:
  * `:timezone_offset` is now `:utc_offset`
  * `:daylight_saving_adjustment` is now `:std_offset`

## [v0.6.5] - 2021-09-01

### Added

* `:cell_id` to the serving system indication (this is an optional field)
* `:timezone_offset` to the serving system indication (this is an optional
  field)
* `:location_area_code` to the serving system indication (this is an optional
  field)
* `:network_datetime` to the serving system indication (this is an optional
  field)
* `:roaming` to the serving system indication (this is an optional field)
* `:network_datetime` to the serving system indication (this is an optional
  field)
* `:daylight_saving_adjustment` to the serving system indication (this is an
  optional field)

## [v0.6.4] - 2021-08-30

### Added

* `:provider` field to the `QMI.NetworkAccess.get_home_network/1` response

## [v0.6.3] - 2021-08-25

### Added

* `QMI.DeviceManagement.get_device_serial_numbers/1`
* Support for Wireless Data Service packet status indication

## [v0.6.2] - 2021-08-20

### Added

* `QMI.DeviceManagement.get_manufacturer/1`
* `QMI.DeviceManagement.get_model/1`
* `QMI.DeviceManagement.get_hardware_rev/1`

## [v0.6.1] - 2021-08-05

### Fixes

* A crash when a response is received after the request has timed out

## [v0.6.0] - 2021-05-27

### Changed

* `QMI.Codec.Indications` to be an internal module

## [v0.5.1] - 2021-05-25

### Added

* `QMI.UserIdentity.read_transparent/3`
* `QMI.UserIdentity.parse_iccid/1`
* Error reasons returned from sending a request

### Fixes

* Timeout crash when requesting a new client id

## [v0.5.0] - 2021-05-14

### Added

* Support for QMI indications

## [v0.4.0] - 2021-05-10

### Changes

* Supervision tree to support driver crashes (backwards incompatible)

## [v0.3.1] - 2021-04-27

### Fixes

* Type spec for `QMI.Codec.NetworkAccess.home_network_report()`
* Error when the device closes and QMI retries to open the device

## [v0.3.0] - 2021-04-26

### Changes

* Rename `:rssis` to `:rssi_reports` in the
 `QMI.Codec.NetworkAccess.signal_strength_report()`

## [v0.2.0] - 2021-04-16

Major refactor

## v0.1.0 - 2021-03-17

Initial release

[v0.9.0]: https://github.com/nerves-networking/qmi/compare/v0.8.6...v0.9.0
[v0.8.6]: https://github.com/nerves-networking/qmi/compare/v0.8.5...v0.8.6
[v0.8.5]: https://github.com/nerves-networking/qmi/compare/v0.8.4...v0.8.5
[v0.8.4]: https://github.com/nerves-networking/qmi/compare/v0.8.3...v0.8.4
[v0.8.3]: https://github.com/nerves-networking/qmi/compare/v0.8.2...v0.8.3
[v0.8.2]: https://github.com/nerves-networking/qmi/compare/v0.8.1...v0.8.2
[v0.8.1]: https://github.com/nerves-networking/qmi/compare/v0.8.0...v0.8.1
[v0.8.0]: https://github.com/nerves-networking/qmi/compare/v0.7.1...v0.8.0
[v0.7.1]: https://github.com/nerves-networking/qmi/compare/v0.7.0...v0.7.1
[v0.7.0]: https://github.com/nerves-networking/qmi/compare/v0.6.5...v0.7.0
[v0.6.5]: https://github.com/nerves-networking/qmi/compare/v0.6.4...v0.6.5
[v0.6.4]: https://github.com/nerves-networking/qmi/compare/v0.6.3...v0.6.4
[v0.6.3]: https://github.com/nerves-networking/qmi/compare/v0.6.2...v0.6.3
[v0.6.2]: https://github.com/nerves-networking/qmi/compare/v0.6.1...v0.6.2
[v0.6.1]: https://github.com/nerves-networking/qmi/compare/v0.6.0...v0.6.1
[v0.6.0]: https://github.com/nerves-networking/qmi/compare/v0.5.0...v0.6.0
[v0.5.1]: https://github.com/nerves-networking/qmi/compare/v0.5.0...v0.5.1
[v0.5.0]: https://github.com/nerves-networking/qmi/compare/v0.4.0...v0.5.0
[v0.4.0]: https://github.com/nerves-networking/qmi/compare/v0.3.1...v0.4.0
[v0.3.1]: https://github.com/nerves-networking/qmi/compare/v0.3.0...v0.3.1
[v0.3.0]: https://github.com/nerves-networking/qmi/compare/v0.2.0...v0.3.0
[v0.2.0]: https://github.com/nerves-networking/qmi/compare/v0.1.0...v0.2.0
