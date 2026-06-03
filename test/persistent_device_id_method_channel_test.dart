import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_device_id/persistent_device_id_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelPersistentDeviceId platform = MethodChannelPersistentDeviceId();
  const MethodChannel channel = MethodChannel('persistent_device_id');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          expect(methodCall.method, 'getDeviceId');
          return 'method-channel-device-id';
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getDeviceId forwards to the native method channel', () async {
    expect(await platform.getDeviceId(), 'method-channel-device-id');
  });

  test(
    'getDeviceId allows null when the platform cannot return an ID',
    () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            channel,
            (MethodCall methodCall) async => null,
          );

      expect(await platform.getDeviceId(), isNull);
    },
  );
}
