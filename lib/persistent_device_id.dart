import 'package:flutter/services.dart';

class PersistentDeviceId {
  static const _channel = MethodChannel('persistent_device_id');

  static Future<String?> getDeviceId() async {
    return await _channel.invokeMethod<String>('getDeviceId');
  }
}
