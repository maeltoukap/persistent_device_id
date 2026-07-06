import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:persistent_device_id/persistent_device_id.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getDeviceId returns a stable value across repeated calls', (
    _,
  ) async {
    final first = await PersistentDeviceId.getDeviceId();
    final second = await PersistentDeviceId.getDeviceId();

    expect(first, isNotNull);
    if (first == null) return;

    expect(first, isNotEmpty);
    expect(second, first);
  });
}
