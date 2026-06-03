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
Android and iOS implementations are expected to return a non-null value in
normal operation.

## Platform Details

### Android

Android first attempts to read a Widevine `MediaDrm` device identifier. When
that is unavailable or fails, the plugin generates a UUID and stores it in
`EncryptedSharedPreferences`, protected by AndroidX Security and Android
Keystore where available.

If encrypted storage cannot be initialized, the plugin falls back to app-private
preferences so the API can still return a stable generated value. That fallback
is less tamper-resistant than encrypted storage and is documented here so apps
can make an informed risk decision.

Minimum Android SDK: 21.

### iOS

iOS generates a UUID and stores it in Keychain using a service-scoped generic
password item. Version 2.0.0 also migrates the legacy account-only Keychain item
used by earlier releases so existing apps can keep their previous identifier.

The Keychain item uses `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, so it
is intended to stay on the same physical device and not migrate through backups
to another device.

Minimum iOS version: 13.0.

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
