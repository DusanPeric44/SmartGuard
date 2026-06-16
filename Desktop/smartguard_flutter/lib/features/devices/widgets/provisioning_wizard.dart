import 'dart:io';

import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/devices/viewmodel/device_list_view_model.dart';

class ProvisioningWizard extends StatefulWidget {
  const ProvisioningWizard({
    super.key,
    required this.vm,
    required this.registrationKey,
  });

  final DeviceListViewModel vm;
  final String registrationKey;

  @override
  State<ProvisioningWizard> createState() => _ProvisioningWizardState();
}

class _ProvisioningWizardState extends State<ProvisioningWizard> {
  int _step = 1;
  final _ssid = TextEditingController();
  final _password = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ssid.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        return AlertDialog(
          title: Text(_title),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_step == 1) _buildStep1(),
                if (_step == 2) _buildStep2(),
                if (_step == 3) _buildStep3(),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: _buildActions(),
        );
      },
    );
  }

  String get _title {
    switch (_step) {
      case 1:
        return 'Povezivanje sa uređajem';
      case 2:
        return 'Podešavanje Wi-Fi mreže';
      case 3:
        return 'Registracija uređaja';
      default:
        return 'Dodaj novi uređaj';
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Molimo vas da se povežete na Wi-Fi pristupnu tačku uređaja.\n\n'
          '1. Otvorite Wi-Fi podešavanja na vašem računaru.\n'
          '2. Pronađite mrežu koja počinje sa "ESP32-SmartCam-AP".\n'
          '3. Povežite se (lozinka je "password123").\n'
          '4. Kada se povežete, kliknite na dugme "Dalje".',
        ),
        const SizedBox(height: 24),
        Center(
          child: OutlinedButton.icon(
            onPressed: _openWifiSettings,
            icon: const Icon(Icons.settings_display),
            label: const Text('Otvori Wi-Fi podešavanja'),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unesite podatke za vašu kućnu Wi-Fi mrežu na koju želite povezati uređaj.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ssid,
          decoration: const InputDecoration(
            labelText: 'Wi-Fi SSID (Naziv mreže)',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Wi-Fi Lozinka',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        const SizedBox(height: 16),
        const CircularProgressIndicator(),
        const SizedBox(height: 24),
        Text(
          widget.vm.provisioningStatus ?? 'Molimo sačekajte...',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Ovaj proces može potrajati do 30 sekundi.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  List<Widget> _buildActions() {
    return [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Otkaži'),
      ),
      if (_step == 1)
        FilledButton(
          onPressed: () => setState(() => _step = 2),
          child: const Text('Dalje'),
        ),
      if (_step == 2)
        FilledButton(
          onPressed: _startProvisioning,
          child: const Text('Poveži uređaj'),
        ),
    ];
  }

  Future<void> _openWifiSettings() async {
    try {
      if (Platform.isWindows) {
        await Process.run('start', [
          'ms-settings:network-wifi',
        ], runInShell: true);
      }
    } catch (_) {
      // Ignore errors opening settings
    }
  }

  Future<void> _startProvisioning() async {
    final s = _ssid.text.trim();
    final p = _password.text.trim();

    if (s.isEmpty) {
      setState(() => _error = 'SSID je obavezan.');
      return;
    }

    setState(() {
      _step = 3;
      _error = null;
    });

    final deviceId = await widget.vm.provisionDevice(
      ssid: s,
      password: p,
      registrationKey: widget.registrationKey,
    );

    if (!mounted) return;
    if (deviceId != null) {
      Navigator.of(context).pop(deviceId);
    }
  }
}
