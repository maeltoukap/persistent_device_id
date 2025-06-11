import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'persistent_device_id_platform_interface.dart';

/// An implementation of [PersistentDeviceIdPlatform] that uses method channels.
class MethodChannelPersistentDeviceId extends PersistentDeviceIdPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('persistent_device_id');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
