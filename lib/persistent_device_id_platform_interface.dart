import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'persistent_device_id_method_channel.dart';

abstract class PersistentDeviceIdPlatform extends PlatformInterface {
  /// Constructs a PersistentDeviceIdPlatform.
  PersistentDeviceIdPlatform() : super(token: _token);

  static final Object _token = Object();

  static PersistentDeviceIdPlatform _instance = MethodChannelPersistentDeviceId();

  /// The default instance of [PersistentDeviceIdPlatform] to use.
  ///
  /// Defaults to [MethodChannelPersistentDeviceId].
  static PersistentDeviceIdPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [PersistentDeviceIdPlatform] when
  /// they register themselves.
  static set instance(PersistentDeviceIdPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
