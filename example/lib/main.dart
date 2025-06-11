import 'package:flutter/material.dart';
import 'package:persistent_device_id/persistent_device_id.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final deviceId = await PersistentDeviceId.getDeviceId();
  runApp(MyApp(deviceId));
}

class MyApp extends StatelessWidget {
  final String? deviceId;
  MyApp(this.deviceId);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Device ID: $deviceId'),
        ),
      ),
    );
  }
}
