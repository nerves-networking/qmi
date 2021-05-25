# Changelog

## v0.5.1

* Improvements
  * Add `QMI.UserIdentity.read_transparent/3`
  * Add `QMI.UserIdentity.parse_iccid/1`
  * Better error reasons returned from sending a request

* Fixes
  * Timeout crash when requesting a new client id

## v0.5.0

* Improvements
  * Add support for QMI indications

## v0.4.0

* Changes
  * Change supervision tree to support driver crashes (backwards incompatible)

## v0.3.1

* Fixes
  * Fix type spec for `QMI.Codec.NetworkAccess.home_network_report()`
  * Fix error when the device closes and QMI retries to open the device

## v0.3.0

* Improvements
  * Clean up unused code
  * Add and update docs

* Changes
  * Change `:rssis` to `:rssi_reports` in the
   `QMI.Codec.NetworkAccess.signal_strength_report()`

## v0.2.0

Major refactor

## v0.1.0

Initial release
