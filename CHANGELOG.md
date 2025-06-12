# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2025-06-11

### ✨ Added
- ✅ iOS support using `keychain` for persistent device identification
- Automatic fallback to UUID stored in the Keychain on iOS
- Improved platform abstraction layer
- Updated README and documentation

---

## [1.0.0] - 2025-06-10

### ✨ Added
- Initial release of `persistent_device_id` 🎉
- Support for Android devices using:
  - `MediaDrm.deviceUniqueId` for hardware-based device IDs (API 18+)
  - Fallback with securely stored UUID using Android Keystore + EncryptedSharedPreferences
- Public method: `PersistentDeviceId.getDeviceId()` to retrieve the unique ID
- Example app demonstrating usage

### ✅ Platform support
- ✅ Android (API 21+)
- 🚧 iOS: not yet implemented (planned)

### 🔐 Security
- Encrypted storage using AndroidX Security library
- No need for runtime permissions
- Persistent across uninstalls (thanks to MediaDrm)

---
