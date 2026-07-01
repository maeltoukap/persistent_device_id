<img src="https://raw.githubusercontent.com/maeltoukap/persistent_device_id/refs/heads/main/assets/persistent_device_id_logo.png" alt="Persistent Device ID Logo" width="200"/>

# persistent_device_id

A Flutter plugin that returns a persistent, app-scoped device identifier for
Android and iOS.

The public API stays intentionally small:

```dart
final deviceId = await PersistentDeviceId.getDeviceId();
```

## What This ID Is

`persistent_device_id` returns an identifier that is stable across repeated app
launches on the same platform installation. It is designed for app diagnostics,
fraud signals, rate limiting, abuse prevention, and other cases where a stable
client-side installation/device signal is useful.

## What This ID Is Not

This value is not a proof of identity, authentication credential, advertising
identifier, or guaranteed hardware serial number. Do not use it as the only
security control for accounts, payments, licensing, or access decisions.

The identifier can change when platform storage is cleared, a device is reset,
operating system behavior changes, or an app is restored/migrated in a way that
does not preserve the underlying storage.

## Supported Platforms

| Platform | Support | Storage strategy |
| -------- | ------- | ---------------- |
| Android  | Yes     | MediaDrm when available, otherwise generated UUID in encrypted app storage |
| iOS      | Yes     | Generated UUID stored in Keychain |

macOS, Windows, Linux, and Web are intentionally not declared in this release.
Browser storage cannot provide the same security or persistence guarantees, and
desktop support should be added only with platform-specific persistence and
tests.

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  persistent_device_id: ^2.0.0
```

Then run:

```bash
flutter pub get
```

## Usage

```dart
import 'package:persistent_device_id/persistent_device_id.dart';

Future<void> loadDeviceId() async {
  final deviceId = await PersistentDeviceId.getDeviceId();
  print('Device ID: $deviceId');
}
```

`getDeviceId()` returns `Future<String?>` to preserve the original public API.
Android and iOS return a generated ID only after it has been durably stored.
A `null` result means the native implementation could not obtain or persist a
stable ID. Method channel errors such as `MissingPluginException` are not
converted to `null` because they indicate an app integration or registration
problem.

## Platform Details

### Android

Android first attempts to read a Widevine `MediaDrm` device identifier. When
that is unavailable or fails, the plugin generates a UUID and stores it in
`EncryptedSharedPreferences`, protected by AndroidX Security and Android
Keystore where available.

If encrypted storage cannot be initialized or written, the plugin uses
app-private `SharedPreferences`. On a later call, an existing app-private ID is
migrated into encrypted storage when it becomes available, without changing the
returned ID. After a successful encrypted write, the old app-private fallback
entry is removed. New IDs are returned only after a synchronous storage write
succeeds. If neither store can persist the ID, the plugin returns `null`.

Minimum Android SDK: 21. AndroidX Security Crypto `1.1.0` supports API 21 and
later. The
[AndroidX Security release notes](https://developer.android.com/jetpack/androidx/releases/security)
note that AndroidKeyStore is not used by the library on API 21 and 22.

### iOS

iOS generates a UUID and stores it in Keychain using a service-scoped generic
password item. Version 2.0.0 also migrates the legacy account-only Keychain item
used by earlier releases so existing apps can keep their previous identifier.
This migration is attempted automatically on the first `getDeviceId()` call
after upgrading. If the migration write fails, the readable legacy ID is still
returned. After a successful scoped Keychain write, the old legacy Keychain item
is deleted.

The Keychain item uses `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, so it
is intended to stay on the same physical device and not migrate through backups
to another device. Missing or corrupted entries are regenerated, but the new ID
is returned only after the Keychain write succeeds. Temporary Keychain
unavailability returns `null` rather than creating a second identity.

Minimum iOS version: 13.0.

## Migration From 1.x

Version 2.0.0 preserves `PersistentDeviceId.getDeviceId()`, but raises the
minimum tooling and platform requirements:

- Dart `^3.11.0` and Flutter `>=3.41.0` are required.
- The iOS deployment target increases from 12.0 to 13.0.
- Existing iOS account-only Keychain IDs are migrated to the service-scoped
  entry on first access, then the legacy item is deleted after a successful
  scoped write.
- Android app-private fallback IDs are migrated to encrypted preferences when
  encrypted storage becomes available, then the plaintext fallback entry is
  removed after a successful encrypted write.
- Consumers should continue handling `null`, which now specifically means no
  durable native ID could be obtained.

## Persistence Limits

The ID is persistent, but not immutable:

- App data clearing can reset Android fallback storage.
- iOS Keychain behavior after uninstall can vary by OS version, app group, and
  installation history.
- Factory reset can reset identifiers.
- Device restore, backup migration, or OS policy changes can reset identifiers.
- Rooted, jailbroken, emulated, or heavily customized devices can behave
  differently.

If your app needs a durable user identity, use your own authenticated backend
identity and treat this package as an additional device/install signal.

## Apple Packaging

The iOS implementation supports modern Flutter Apple packaging with Swift
Package Manager-friendly source layout while keeping CocoaPods support for
projects that have not migrated yet.

## Example

Run the bundled example app:

```bash
cd example
flutter run
```

The example shows loading, refreshing, copying, and displaying error/null states
for the device ID.

## License

MIT License. See [LICENSE](LICENSE).
