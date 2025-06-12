<img src="https://raw.githubusercontent.com/maeltoukap/persistent_device_id/refs/heads/main/assets/persistent_device_id_logo.png" alt="Persistent Device ID Logo" width="200"/>

# 📱 persistent\_device\_id

A Flutter plugin that provides a **unique, persistent, and secure** device identifier—**even after reinstalling the app or resetting the device**.
Supports **Android** and **iOS** using system-level cryptography and secure storage.

---

## ✨ Features

* 🔒 Generates a **unique and persistent ID per device**
* ♻️ Persists across app reinstalls, cache wipes, and even factory resets (when possible)
* 🛡️ Uses **MediaDrm**, **Android Keystore**, and **EncryptedSharedPreferences** on Android
* 🍏 Uses **Keychain** on iOS
* 🚫 Requires **no runtime permissions**
* 📦 Simple, asynchronous API

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  persistent_device_id: <latest_version>
```

Then run:

```bash
flutter pub get
```

---

## 🛠️ Usage

### Import the package

```dart
import 'package:persistent_device_id/persistent_device_id.dart';
```

### Get the device ID

```dart
final deviceId = await PersistentDeviceId.getDeviceId();
print("Device ID: $deviceId");
```

---

## ⚙️ Supported Platforms

| Platform | Support |
| -------- | ------- |
| Android  | ✅ Yes   |
| iOS      | ✅ Yes   |

---

## 🧠 How It Works

This plugin uses **different secure layers per platform** to persist a device-unique identifier:

### Android

1. Attempts to derive a hardware-based ID from [`MediaDrm`](https://developer.android.com/reference/android/media/MediaDrm) (API ≥ 18).
2. If `MediaDrm` is not supported or fails (e.g. on rooted/custom ROM devices), falls back to:

   * A generated UUID
   * Stored in [`EncryptedSharedPreferences`](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences)
   * Protected by the [`Android Keystore`](https://developer.android.com/training/articles/keystore)

### iOS

* Uses the [`Keychain`](https://developer.apple.com/documentation/security/keychain_services) to securely store and persist a generated UUID.

---

## ✅ Android Requirements

* **minSdkVersion**: 21
* **compileSdkVersion**: 34
* No special permissions needed

---

## 🚧 Limitations

* `MediaDrm` only available on Android **API ≥ 18**
* On some custom or rooted ROMs, `MediaDrm` may be unreliable
* Factory reset will remove the ID unless hardware-backed
* On iOS, Keychain-based ID may reset **if iCloud Keychain is disabled** or device is **restored without backup**

---

## 🔍 Example

Clone the repository and run the example app:

```bash
cd example
flutter run
```

---

## 📄 License

MIT License. © 2025 Mael Toukap.

---

## 🙋‍♂️ Contributing

Contributions are welcome! Please open an issue or submit a pull request on [GitHub](https://github.com/maeltoukap/persistent_device_id)
