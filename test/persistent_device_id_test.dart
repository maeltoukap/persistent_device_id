import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_device_id/persistent_device_id.dart';
import 'package:persistent_device_id/persistent_device_id_method_channel.dart';
import 'package:persistent_device_id/persistent_device_id_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPersistentDeviceIdPlatform
    with MockPlatformInterfaceMixin
    implements PersistentDeviceIdPlatform {
  MockPersistentDeviceIdPlatform(this.deviceId);

  final String? deviceId;
  int calls = 0;

  @override
  Future<String?> getDeviceId() async {
    calls += 1;
    return deviceId;
  }
}

void main() {
  final initialPlatform = PersistentDeviceIdPlatform.instance;

  tearDown(() {
    PersistentDeviceIdPlatform.instance = initialPlatform;
  });

  test('$MethodChannelPersistentDeviceId is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPersistentDeviceId>());
  });

  test('getDeviceId delegates through the platform interface', () async {
    final platform = MockPersistentDeviceIdPlatform('device-123');
    PersistentDeviceIdPlatform.instance = platform;

    expect(await PersistentDeviceId.getDeviceId(), 'device-123');
    expect(platform.calls, 1);
  });

  test('getDeviceId preserves nullable API contract', () async {
    PersistentDeviceIdPlatform.instance = MockPersistentDeviceIdPlatform(null);

    expect(await PersistentDeviceId.getDeviceId(), isNull);
  });

  test('repeated calls can return the same persistent ID', () async {
    final platform = MockPersistentDeviceIdPlatform('stable-device-id');
    PersistentDeviceIdPlatform.instance = platform;

    expect(await PersistentDeviceId.getDeviceId(), 'stable-device-id');
    expect(await PersistentDeviceId.getDeviceId(), 'stable-device-id');
    expect(platform.calls, 2);
  });
}
