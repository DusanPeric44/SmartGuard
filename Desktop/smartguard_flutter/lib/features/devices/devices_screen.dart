import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/features/devices/data/api_devices_repository.dart';
import 'package:smartguard_flutter/features/devices/data/devices_repository.dart';
import 'package:smartguard_flutter/features/devices/model/device_models.dart';
import 'package:smartguard_flutter/features/devices/viewmodel/device_details_view_model.dart';
import 'package:smartguard_flutter/features/devices/viewmodel/device_list_view_model.dart';
import 'package:smartguard_flutter/features/devices/widgets/device_assign_users_dialog.dart';
import 'package:smartguard_flutter/features/devices/widgets/device_status_chip.dart';
import 'package:smartguard_flutter/features/devices/widgets/devices_filters_card.dart';
import 'package:smartguard_flutter/features/devices/widgets/provisioning_wizard.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  DevicesRepository? _repo;
  DeviceListViewModel? _vm;
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
        DevicesFiltersCard(
          statusName: _statusName,
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
      builder: (context) => ProvisioningWizard(vm: vm, registrationKey: key),
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
                            DeviceStatusChip(
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

class DeviceDetailsScreen extends StatefulWidget {
  const DeviceDetailsScreen({super.key, required this.deviceId});

  final String deviceId;

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  DevicesRepository? _repo;
  DeviceDetailsViewModel? _vm;
  final _nameController = TextEditingController();

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
    _nameController.dispose();
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
    final canEditName = caps.canManageDevices && !vm.isLoading;
    final canConfirmRename =
        vm.isEditingName &&
        vm.pendingName.trim().isNotEmpty &&
        vm.pendingName.trim() != device.name;
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
                      if (!vm.isEditingName)
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: !canEditName
                                    ? null
                                    : () {
                                        _nameController.text = device.name;
                                        vm.beginEditName();
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    device.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineSmall,
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit name',
                              onPressed: !canEditName
                                  ? null
                                  : () {
                                      _nameController.text = device.name;
                                      vm.beginEditName();
                                    },
                              icon: const Icon(Icons.edit_outlined),
                            ),
                          ],
                        )
                      else
                        TextField(
                          controller: _nameController,
                          autofocus: true,
                          enabled: !vm.isLoading,
                          onChanged: vm.setPendingName,
                          style: Theme.of(context).textTheme.headlineSmall,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Cancel',
                                  onPressed: vm.isLoading
                                      ? null
                                      : () {
                                          vm.cancelEditName();
                                        },
                                  icon: const Icon(Icons.close),
                                ),
                                IconButton(
                                  tooltip: 'Confirm',
                                  onPressed: !canConfirmRename
                                      ? null
                                      : () async {
                                          final ok = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Rename device',
                                              ),
                                              content: const Text(
                                                'Are you sure you want to change device name?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                                  child: const Text('Cancel'),
                                                ),
                                                FilledButton(
                                                  onPressed: () => Navigator.of(
                                                    context,
                                                  ).pop(true),
                                                  child: const Text('Confirm'),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (ok != true) return;
                                          if (!context.mounted) return;
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          final renamed = await vm
                                              .renameDevice();
                                          if (!context.mounted) return;
                                          messenger.showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                renamed
                                                    ? 'Name updated.'
                                                    : (vm.errorMessage ??
                                                          'Greška.'),
                                              ),
                                            ),
                                          );
                                        },
                                  icon: const Icon(Icons.check),
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text('ID: ${device.id}'),
                      const SizedBox(height: 12),
                      DeviceStatusChip(
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
          DeviceAssignUsersDialog(allUsers: all, selected: selected),
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

String _ddmmhhmm(DateTime dt) {
  final d = dt.day.toString().padLeft(2, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$d/$m $h:$mm';
}
