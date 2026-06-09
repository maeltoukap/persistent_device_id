import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:persistent_device_id/persistent_device_id.dart';

void main() {
  runApp(const PersistentDeviceIdExampleApp());
}

class PersistentDeviceIdExampleApp extends StatelessWidget {
  const PersistentDeviceIdExampleApp({
    super.key,
    this.loadDeviceId = PersistentDeviceId.getDeviceId,
  });

  final Future<String?> Function() loadDeviceId;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Persistent Device ID Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        useMaterial3: true,
      ),
      home: DeviceIdScreen(loadDeviceId: loadDeviceId),
    );
  }
}

class DeviceIdScreen extends StatefulWidget {
  const DeviceIdScreen({required this.loadDeviceId, super.key});

  final Future<String?> Function() loadDeviceId;

  @override
  State<DeviceIdScreen> createState() => _DeviceIdScreenState();
}

class _DeviceIdScreenState extends State<DeviceIdScreen> {
  String? _deviceId;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  Future<void> _loadDeviceId() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final deviceId = await widget.loadDeviceId();
      if (!mounted) return;
      setState(() {
        _deviceId = deviceId;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deviceId = null;
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _copyDeviceId() async {
    final deviceId = _deviceId;
    if (deviceId == null || deviceId.isEmpty) return;

    await Clipboard.setData(ClipboardData(text: deviceId));
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Device ID copied')));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('persistent_device_id'),
        backgroundColor: colorScheme.surfaceContainerHighest,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Persistent Device ID',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'This example loads the Android/iOS identifier exposed by '
                  'PersistentDeviceId.getDeviceId().',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerHighest,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _DeviceIdValue(
                      deviceId: _deviceId,
                      error: _error,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      key: const ValueKey('refresh-device-id'),
                      onPressed: _isLoading ? null : _loadDeviceId,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                    OutlinedButton.icon(
                      key: const ValueKey('copy-device-id'),
                      onPressed: _deviceId == null ? null : _copyDeviceId,
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceIdValue extends StatelessWidget {
  const _DeviceIdValue({
    required this.deviceId,
    required this.error,
    required this.isLoading,
  });

  final String? deviceId;
  final Object? error;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Loading device ID...'),
        ],
      );
    }

    if (error != null) {
      return Text(
        'Failed to load device ID: $error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
        textAlign: TextAlign.center,
      );
    }

    final deviceId = this.deviceId;
    if (deviceId == null || deviceId.isEmpty) {
      return const Text(
        'The platform returned no device ID.',
        textAlign: TextAlign.center,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Device ID', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        SelectableText(
          deviceId,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
