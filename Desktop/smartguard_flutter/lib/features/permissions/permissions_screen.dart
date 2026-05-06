import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/features/permissions/viewmodel/permissions_view_model.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  PermissionsViewModel? _vm;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final role = AppScope.of(context).auth.role;
      final vm = PermissionsViewModel(currentUserRole: role);
      vm.addListener(_onVmChanged);
      vm.init();
      setState(() => _vm = vm);
    });
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
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

    final role = vm.currentUserRole;
    final caps = AppCapabilities.fromRole(role);

    return ListView(
      children: [
        _RoleSummary(role: role, caps: caps),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildUserManagement(context, vm),
          ),
        ),
      ],
    );
  }

  Widget _buildUserManagement(BuildContext context, PermissionsViewModel vm) {
    if (vm.isLoading && vm.users.isEmpty) {
      return const AsyncStatePanel.loading();
    }
    if (vm.errorMessage != null && vm.users.isEmpty) {
      return AsyncStatePanel.error(
        errorMessage: vm.errorMessage!,
        onRetry: vm.init,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Korisnici',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            if (vm.canManageUsers) ...[
              TextButton(
                onPressed: vm.pendingRoleChanges.isEmpty || vm.isLoading
                    ? null
                    : vm.discardChanges,
                child: const Text('Discard'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: vm.pendingRoleChanges.isEmpty || vm.isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final ok = await vm.saveChanges();
                        if (!mounted) return;
                        if (ok) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Promjene sačuvane.')),
                          );
                        } else {
                          messenger.showSnackBar(
                            SnackBar(content: Text(vm.errorMessage ?? 'Greška.')),
                          );
                        }
                      },
                icon: vm.isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          vm.canManageUsers
              ? 'Admin može mijenjati role korisnika. Promjene su batch-ovane i čuvaju se tek na Save.'
              : 'Nemate dozvolu da mijenjate role. Prikaz je read-only.',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Username')),
              DataColumn(label: Text('Role')),
            ],
            rows: [
              for (final u in vm.users)
                DataRow(
                  cells: [
                    DataCell(Text(u.username)),
                    DataCell(
                      vm.canManageUsers
                          ? DropdownButton<UserRole>(
                              value: vm.pendingRoleChanges[u.id] ?? u.role,
                              onChanged: vm.isLoading
                                  ? null
                                  : (v) => v == null ? null : vm.setRoleDraft(u.id, v),
                              items: const [
                                DropdownMenuItem(
                                  value: UserRole.admin,
                                  child: Text('admin'),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.homeowner,
                                  child: Text('homeowner'),
                                ),
                                DropdownMenuItem(
                                  value: UserRole.viewer,
                                  child: Text('viewer'),
                                ),
                              ],
                            )
                          : Text(userRoleToWire(u.role)),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleSummary extends StatelessWidget {
  const _RoleSummary({
    required this.role,
    required this.caps,
  });

  final UserRole role;
  final AppCapabilities caps;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Effective role: ${userRoleToWire(role)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CapChip(label: 'canStream', value: caps.canStream),
                _CapChip(label: 'canDownload', value: caps.canDownload),
                _CapChip(label: 'canManageUsers', value: caps.canManageUsers),
                _CapChip(label: 'canManageDevices', value: caps.canManageDevices),
                _CapChip(label: 'canEditReferenceData', value: caps.canEditReferenceData),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CapChip extends StatelessWidget {
  const _CapChip({required this.label, required this.value});

  final String label;
  final bool value;

  @override
  Widget build(BuildContext context) {
    final color = value ? Colors.greenAccent.shade400 : Colors.blueGrey.shade300;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text('$label: ${value ? 'true' : 'false'}'),
    );
  }
}
