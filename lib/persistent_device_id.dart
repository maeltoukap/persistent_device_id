import 'persistent_device_id_platform_interface.dart';

/// Provides access to the persistent app-scoped device identifier.
class PersistentDeviceId {
  /// Returns the persistent identifier reported by the current platform.
  ///
  /// The identifier is platform-specific and can be `null` only if the platform
  /// implementation cannot produce a value.
  static Future<String?> getDeviceId() async {
    return PersistentDeviceIdPlatform.instance.getDeviceId();
  }
}
