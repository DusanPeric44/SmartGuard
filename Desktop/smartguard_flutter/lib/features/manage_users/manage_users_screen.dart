import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/features/manage_users/data/api_users_repository.dart';
import 'package:smartguard_flutter/features/manage_users/data/users_repository.dart';
import 'package:smartguard_flutter/features/manage_users/model/managed_user.dart';
import 'package:smartguard_flutter/features/manage_users/viewmodel/manage_users_view_model.dart';
import 'package:smartguard_flutter/features/manage_users/widgets/manage_users_filters_card.dart';
import 'package:smartguard_flutter/features/manage_users/widgets/upsert_user_dialog.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  UsersRepository? _repo;
  ManageUsersViewModel? _vm;
  final _termController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = ApiUsersRepository(api: AppScope.of(context).api);
    _vm = ManageUsersViewModel(repository: _repo!);
    _vm!.addListener(_onVmChanged);
    _vm!.init();
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
    _termController.dispose();
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

    return Column(
      children: [
        ManageUsersFiltersCard(
          controller: _termController,
          onTermChanged: vm.setTerm,
          onRefresh: vm.load,
          onAddUser: caps.canManageUsers ? () => _openUpsertDialog(vm) : null,
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _buildBody(context: context, caps: caps, vm: vm),
        ),
      ],
    );
  }

  Widget _buildBody({
    required BuildContext context,
    required AppCapabilities caps,
    required ManageUsersViewModel vm,
  }) {
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
                'No users.',
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
                    DataColumn(label: Text('Email')),
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: [
                    for (final u in vm.items)
                      DataRow(
                        cells: [
                          DataCell(Text(u.email)),
                          DataCell(Text(userRoleToWire(u.role))),
                          DataCell(
                            Builder(
                              builder: (context) {
                                final busy = vm.rowBusy[u.id] == true;
                                final reason = !caps.canManageUsers
                                    ? 'Unavailable for your role'
                                    : (busy ? 'Action in progress…' : '');
                                final disabled = !caps.canManageUsers || busy;
                                return Row(
                                  children: [
                                    IconButton(
                                      tooltip: reason.isEmpty ? 'Edit' : reason,
                                      onPressed: disabled
                                          ? null
                                          : () => _openUpsertDialog(vm, user: u),
                                      icon: const Icon(Icons.edit_outlined),
                                    ),
                                    IconButton(
                                      tooltip: reason.isEmpty
                                          ? 'Delete'
                                          : reason,
                                      onPressed: disabled
                                          ? null
                                          : () => _confirmDelete(vm, u),
                                      icon: const Icon(Icons.delete_outline),
                                    ),
                                    if (busy)
                                      const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                  ],
                                );
                              },
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
                padding: const EdgeInsets.all(8),
                child: OutlinedButton(
                  onPressed: vm.isLoading ? null : vm.loadMore,
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load more'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(ManageUsersViewModel vm, ManagedUser user) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete user'),
        content: Text('Delete ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (res != true) return;

    final ok = await vm.deleteUser(user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'User deleted.' : (vm.errorMessage ?? 'Error.')),
      ),
    );
  }

  Future<void> _openUpsertDialog(
    ManageUsersViewModel vm, {
    ManagedUser? user,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpsertUserDialog(vm: vm, user: user),
    );

    if (res == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(user == null ? 'User created.' : 'User updated.'),
        ),
      );
    }
  }
}
