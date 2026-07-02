# Changelog

## 2.0.0 - 2026-06-03

### Changed
- Raised the package SDK floor to Dart `^3.11.0` and Flutter `>=3.41.0`.
- Kept the public API stable as `PersistentDeviceId.getDeviceId()`.
- Routed the Dart API through the platform interface and removed scaffolded
  `getPlatformVersion` code.
- Updated AndroidX Security Crypto to stable `1.1.0`.
- Lowered Android minSdk to 21.
- Changed Android fallback writes to synchronous, checked persistence and added
  migration from app-private fallback storage into encrypted preferences,
  removing the plaintext fallback entry after a successful encrypted write.
- Moved iOS source into a Swift Package Manager-friendly layout while keeping
  CocoaPods support.
- Updated iOS Keychain storage to use a service-scoped item and migrate the
  legacy account-only item from earlier releases while preferring the new
  service-scoped entry on subsequent reads.
- Made iOS Keychain reads status-aware so temporary storage failures return
  `null` instead of creating a second identifier.
- Rewrote README documentation with clearer guarantees, platform differences,
  and persistence limitations.
- Refreshed package metadata, tests, and the example app for publish readiness.
- Kept the example integration-test plugin available to Flutter 3.44 release
  builds so the generated Android plugin registrant compiles successfully.

### Added
- Swift Package Manager manifest for iOS.
- Privacy manifest bundling through both Swift Package Manager and CocoaPods.
- Dart tests for API stability, repeated calls, method-channel forwarding, and
  nullable platform responses.
- Android native unit tests for `getDeviceId` and unknown method handling.
- Native persistence tests for failed writes, fallback migration, corrupted
  values, legacy Keychain migration, and unavailable storage.

### Migration from 1.x
- The Dart API remains `PersistentDeviceId.getDeviceId()`.
- Dart `^3.11.0` and Flutter `>=3.41.0` are now required.
- The iOS deployment target increases from 12.0 to 13.0.
- Existing iOS account-only Keychain IDs are migrated automatically on the
  first call after upgrading. A readable legacy ID remains valid even if the
  migration write cannot complete. The migrated scoped entry is preferred on
  later reads, while the legacy item remains until it can be removed safely.
- Android app-private fallback IDs are migrated into encrypted preferences when
  encrypted storage becomes available. The plaintext fallback entry is removed
  only after a successful encrypted write.
- A `null` result means the native implementation could not obtain or durably
  persist an ID. Method channel registration errors continue to throw.

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
