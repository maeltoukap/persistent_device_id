import 'persistent_device_id_platform_interface.dart';

/// Provides access to the persistent app-scoped device identifier.
class PersistentDeviceId {
  /// Returns the persistent identifier reported by the current platform.
  ///
  /// The identifier is platform-specific. A `null` result means the native
  /// implementation could not obtain or durably persist an identifier.
  /// Method channel errors are allowed to surface as integration failures.
  static Future<String?> getDeviceId() async {
    return PersistentDeviceIdPlatform.instance.getDeviceId();
  }
}
