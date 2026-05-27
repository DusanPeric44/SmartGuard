import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/features/devices/data/api_devices_repository.dart';
import 'package:smartguard_flutter/features/devices/data/devices_repository.dart';
import 'package:smartguard_flutter/features/devices/model/device_models.dart';
import 'package:smartguard_flutter/features/devices/viewmodel/device_details_view_model.dart';
import 'package:smartguard_flutter/features/devices/viewmodel/device_list_view_model.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  DevicesRepository? _repo;
  DeviceListViewModel? _vm;
  final _searchController = TextEditingController();
  String? _statusName;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo == null) {
      _repo = _buildRepository();
      _vm = DeviceListViewModel(repository: _repo!);
      _vm!.addListener(_onVmChanged);
      _vm!.init();
    }
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  DevicesRepository _buildRepository() {
    return ApiDevicesRepository(api: AppScope.of(context).api);
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Center(child: CircularProgressIndicator());

    final auth = AppScope.of(context).auth;
    final caps = AppCapabilities.fromRole(auth.role);

    return Column(
      children: [
        _FiltersCard(
          controller: _searchController,
          statusName: _statusName,
          onSearchChanged: (v) => vm.setSearch(v),
          onStatusChanged: (v) async {
            _statusName = v;
            await vm.setStatus(v);
          },
          onRefresh: vm.load,
          onAddDevice: _openProvisioningWizard,
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildBody(context, caps, vm)),
      ],
    );
  }

  Future<void> _openProvisioningWizard() async {
    final vm = _vm;
    if (vm == null) return;

    final auth = AppScope.of(context).auth;
    final key = auth.registrationKey;
    if (key == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Greška: Registracijski ključ nije dostupan.'),
        ),
      );
      return;
    }

    final deviceId = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ProvisioningWizard(vm: vm, registrationKey: key),
    );

    if (deviceId != null && mounted) {
      context.go('/devices/$deviceId');
    }
  }

  Widget _buildBody(
    BuildContext context,
    AppCapabilities caps,
    DeviceListViewModel vm,
  ) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (vm.errorMessage != null && vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.error(
          errorMessage: vm.errorMessage!,
          onRetry: vm.load,
        ),
      );
    }
    if (vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.content(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Nema uređaja.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final d in vm.items)
                      DataRow(
                        cells: [
                          DataCell(
                            Text(d.name),
                            onTap: () => context.go('/devices/${d.id}'),
                          ),

                          DataCell(
                            _StatusChip(
                              status: d.status ?? DeviceStatus(0, 'Offline'),
                            ),
                          ),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Open',
                                  onPressed: () =>
                                      context.go('/devices/${d.id}'),
                                  icon: const Icon(Icons.open_in_new),
                                ),
                                if (vm.rowBusy[d.id] == true)
                                  const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (vm.hasMore)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: OutlinedButton(
                  onPressed: vm.isLoading ? null : vm.loadMore,
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Učitaj više'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProvisioningWizard extends StatefulWidget {
  const _ProvisioningWizard({required this.vm, required this.registrationKey});

  final DeviceListViewModel vm;
  final String registrationKey;

  @override
  State<_ProvisioningWizard> createState() => _ProvisioningWizardState();
}

class _ProvisioningWizardState extends State<_ProvisioningWizard> {
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
    if (_step == 3) return [];

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

    if (deviceId != null) {
      if (mounted) Navigator.of(context).pop(deviceId);
    } else {
      setState(() {
        _step = 2;
        _error =
            'Uređaj nije pronađen nakon 30 sekundi. Molimo pokušajte ponovo (povežite se na ESP32 AP i ponovite unos).';
      });
    }
  }
}

class DeviceDetailsScreen extends StatefulWidget {
  const DeviceDetailsScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  DevicesRepository? _repo;
  DeviceDetailsViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = ApiDevicesRepository(api: AppScope.of(context).api);
    _vm = DeviceDetailsViewModel(repository: _repo!, deviceId: widget.deviceId);
    _vm!.addListener(_onVmChanged);
    _vm!.init();
  }

  @override
  void didUpdateWidget(covariant DeviceDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceId == widget.deviceId) return;
    final repo = _repo;
    if (repo == null) return;

    final previousVm = _vm;
    if (previousVm != null) {
      previousVm.removeListener(_onVmChanged);
      previousVm.dispose();
    }

    final newVm = DeviceDetailsViewModel(
      repository: repo,
      deviceId: widget.deviceId,
    );
    _vm = newVm;
    newVm.addListener(_onVmChanged);
    newVm.init();
  }

  @override
  void dispose() {
    final vm = _vm;
    if (vm != null) {
      vm.removeListener(_onVmChanged);
      vm.dispose();
    }
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) {
      return const Center(child: AsyncStatePanel.loading());
    }

    final caps = AppCapabilities.fromRole(AppScope.of(context).auth.role);
    final details = vm.details;

    if (vm.isLoading && details == null) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (vm.errorMessage != null && details == null) {
      return Center(
        child: AsyncStatePanel.error(
          errorMessage: vm.errorMessage!,
          onRetry: vm.load,
        ),
      );
    }
    if (details == null) return const SizedBox.shrink();

    final device = details.device;
    return ListView(
      children: [
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: () => context.go('/devices'),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Nazad'),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: (!caps.canManageDevices || vm.isLoading)
                  ? null
                  : () => _openAssignUsers(details),
              icon: const Icon(Icons.group_add_outlined),
              label: const Text('Assign users'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: 420,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${device.id}'),
                      const SizedBox(height: 12),
                      _StatusChip(
                        status: device.status ?? DeviceStatus(0, 'Offline'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Last seen: ${device.status?.name == "Online" ? 'Now' : _ddmmhhmm(details.lastSeenAt)}',
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 420,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned users',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (details.assignedUsers.isEmpty)
                        const Text('Nema dodijeljenih korisnika.')
                      else
                        for (final u in details.assignedUsers)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.person_outline),
                                const SizedBox(width: 8),
                                Text(u.username),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openAssignUsers(DeviceDetails details) async {
    final vm = _vm;
    if (vm == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final all = vm.allUsers;
    final selected = details.assignedUsers.map((u) => u.id).toSet();

    final res = await showDialog<Set<String>>(
      context: context,
      builder: (context) =>
          _AssignUsersDialog(allUsers: all, selected: selected),
    );
    if (res == null) return;

    final ok = await vm.saveAssignments(res.toList(growable: false));
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Dodjela sačuvana.' : (vm.errorMessage ?? 'Greška.'),
        ),
      ),
    );
  }
}

class _AssignUsersDialog extends StatefulWidget {
  const _AssignUsersDialog({required this.allUsers, required this.selected});

  final List<DeviceUser> allUsers;
  final Set<String> selected;

  @override
  State<_AssignUsersDialog> createState() => _AssignUsersDialogState();
}

class _AssignUsersDialogState extends State<_AssignUsersDialog> {
  late final Set<String> _selected = Set<String>.from(widget.selected);
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? widget.allUsers
        : widget.allUsers
              .where((u) => u.email.toLowerCase().contains(q))
              .toList(growable: false);

    return AlertDialog(
      title: const Text('Assign users'),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search users',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final u = filtered[index];
                  final selected = _selected.contains(u.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                          _selected.add(u.id);
                        } else {
                          _selected.remove(u.id);
                        }
                      });
                    },
                    title: Text(u.email),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Otkaži'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selected),
          child: const Text('Sačuvaj'),
        ),
      ],
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.controller,
    required this.statusName,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onRefresh,
    this.onAddDevice,
  });

  final TextEditingController controller;
  final String? statusName;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onStatusChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAddDevice;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: controller,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Name, ID, IP...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String?>(
                initialValue: statusName,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('All')),
                  DropdownMenuItem<String?>(
                    value: 'Online',
                    child: Text('Online'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Offline',
                    child: Text('Offline'),
                  ),
                  DropdownMenuItem<String?>(
                    value: 'Maintenance',
                    child: Text('Maintenance'),
                  ),
                ],
                onChanged: onStatusChanged,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            if (onAddDevice != null)
              FilledButton.icon(
                onPressed: onAddDevice,
                icon: const Icon(Icons.add),
                label: const Text('Add New Device'),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DeviceStatus status;

  @override
  Widget build(BuildContext context) {
    final label = status.name;
    final color = _statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(label),
    );
  }
}

Color _statusColor(BuildContext context, DeviceStatus status) {
  switch (status.name) {
    case 'Online':
      return Colors.greenAccent.shade400;
    case 'Offline':
      return Colors.blueGrey.shade300;
    case 'Maintenance':
      return Colors.amberAccent.shade400;
    default:
      return Colors.grey;
  }
}

String _ddmmhhmm(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$d/$m $h:$mm';
}
