# 📱 persistent\_device\_id

A Flutter plugin that provides a **unique, persistent, and secure** device identifier on Android—even after uninstalling and reinstalling the app.

---

## ✨ Features

* 🔒 Generates a unique ID per device
* ♻️ Persists across app reinstalls (on Android API ≥ 18 with MediaDrm)
* 🧱 Securely stored using Android Keystore + EncryptedSharedPreferences
* 🚫 No runtime permissions required
* 📦 Simple, asynchronous API

---

## 📦 Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  persistent_device_id: <version>
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

| Platform | Support                  |
| -------- | ------------------------ |
| Android  | ✅ Yes                   |
| iOS      | 🚧 Not yet (coming soon) |

---

## 🧠 How It Works

1. On Android (API ≥ 18), the plugin attempts to use [`MediaDrm`](https://developer.android.com/reference/android/media/MediaDrm) to derive a hardware-based identifier.
2. If `MediaDrm` is unavailable or fails (e.g. on rooted devices), a fallback UUID is generated once and securely stored using:

   * [`EncryptedSharedPreferences`](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences)
   * [`Android Keystore`](https://developer.android.com/training/articles/keystore)

---

## ✅ Android Requirements

* **minSdkVersion**: 21
* **compileSdkVersion**: 34
* No permissions required

---

## 🚧 Limitations

* `MediaDrm` is only available on **Android API 18 (Jelly Bean 4.3)** and above.
* On some rooted or modified devices, `MediaDrm` may fail or behave inconsistently.
* iOS support is currently not available.

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

Contributions are welcome! Please open an issue or submit a pull request on [GitHub](https://github.com/maeltoukap/persistent_device_id).