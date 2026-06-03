import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:persistent_device_id_example/main.dart';

void main() {
  testWidgets('shows the loaded device ID', (tester) async {
    await tester.pumpWidget(
      PersistentDeviceIdExampleApp(
        loadDeviceId: () async => 'example-device-id',
      ),
    );

    expect(find.text('Loading device ID...'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('example-device-id'), findsOneWidget);
    expect(find.byKey(const ValueKey('copy-device-id')), findsOneWidget);
  });

  testWidgets('refreshes the device ID', (tester) async {
    var calls = 0;

    await tester.pumpWidget(
      PersistentDeviceIdExampleApp(
        loadDeviceId: () async {
          calls += 1;
          return 'example-device-id-$calls';
        },
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('example-device-id-1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('refresh-device-id')));
    await tester.pumpAndSettle();

    expect(find.text('example-device-id-2'), findsOneWidget);
  });

  testWidgets('shows a null device ID state', (tester) async {
    await tester.pumpWidget(
      PersistentDeviceIdExampleApp(
        loadDeviceId: () async => null,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('The platform returned no device ID.'), findsOneWidget);
  });
}
