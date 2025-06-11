import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_device_id/persistent_device_id.dart';
import 'package:persistent_device_id/persistent_device_id_platform_interface.dart';
import 'package:persistent_device_id/persistent_device_id_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPersistentDeviceIdPlatform
    with MockPlatformInterfaceMixin
    implements PersistentDeviceIdPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final PersistentDeviceIdPlatform initialPlatform = PersistentDeviceIdPlatform.instance;

  test('$MethodChannelPersistentDeviceId is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelPersistentDeviceId>());
  });

  test('getPlatformVersion', () async {
    PersistentDeviceId persistentDeviceIdPlugin = PersistentDeviceId();
    MockPersistentDeviceIdPlatform fakePlatform = MockPersistentDeviceIdPlatform();
    PersistentDeviceIdPlatform.instance = fakePlatform;

    expect(await persistentDeviceIdPlugin.getPlatformVersion(), '42');
  });
}
