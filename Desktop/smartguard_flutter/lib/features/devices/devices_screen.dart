import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartguard_flutter/features/placeholder/placeholder_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Device Management',
      subtitle:
          'Skeleton lista uređaja. Ostavljen je primjer navigacije na detalje uređaja preko rute i deep linka.',
      actions: [
        FilledButton.tonalIcon(
          onPressed: () => context.go('/devices/camera-01'),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Otvori detalje uređaja'),
        ),
      ],
    );
  }
}

class DeviceDetailsScreen extends StatelessWidget {
  const DeviceDetailsScreen({
    super.key,
    required this.deviceId,
  });

  final String deviceId;

  @override
  Widget build(BuildContext context) {
    return PlaceholderScreen(
      title: 'Device Details',
      subtitle:
          'Deep link i routing primjer za uređaj `$deviceId`. Backend integracija i detaljni widgeti dolaze kasnije.',
      actions: [
        FilledButton.tonal(
          onPressed: () => context.go('/devices'),
          child: const Text('Nazad na listu uređaja'),
        ),
      ],
    );
  }
}
