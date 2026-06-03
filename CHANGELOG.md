# Changelog

## 2.0.0 - 2026-06-03

### Changed
- Raised the package SDK floor to Dart `^3.11.0` and Flutter `>=3.41.0`.
- Kept the public API stable as `PersistentDeviceId.getDeviceId()`.
- Routed the Dart API through the platform interface and removed scaffolded
  `getPlatformVersion` code.
- Updated AndroidX Security Crypto to stable `1.1.0`.
- Lowered Android minSdk to 21.
- Moved iOS source into a Swift Package Manager-friendly layout while keeping
  CocoaPods support.
- Updated iOS Keychain storage to use a service-scoped item and migrate the
  legacy account-only item from earlier releases.
- Rewrote README documentation with clearer guarantees, platform differences,
  and persistence limitations.
- Refreshed package metadata, tests, and the example app for publish readiness.

### Added
- Swift Package Manager manifest for iOS.
- Privacy manifest bundling through both Swift Package Manager and CocoaPods.
- Dart tests for API stability, repeated calls, method-channel forwarding, and
  nullable platform responses.
- Android native unit tests for `getDeviceId` and unknown method handling.

## 1.1.0 - 2025-06-11

### Added
- iOS support using Keychain for persistent device identification.
- Automatic fallback to a generated UUID stored in the Keychain on iOS.
- Improved platform abstraction layer.
- Updated README and documentation.

## 1.0.0 - 2025-06-10

### Added
- Initial release of `persistent_device_id`.
- Android support using `MediaDrm.deviceUniqueId` where available.
- Fallback UUID storage using Android Keystore and encrypted shared preferences.
- Public method: `PersistentDeviceId.getDeviceId()`.
- Example app demonstrating usage.
