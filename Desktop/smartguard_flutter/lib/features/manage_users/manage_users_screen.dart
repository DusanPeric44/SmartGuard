import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/app_capabilities.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/features/manage_users/data/api_users_repository.dart';
import 'package:smartguard_flutter/features/manage_users/data/users_repository.dart';
import 'package:smartguard_flutter/features/manage_users/model/managed_user.dart';
import 'package:smartguard_flutter/features/manage_users/viewmodel/manage_users_view_model.dart';
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
        _FiltersCard(
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
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  onPressed:
                                      (!caps.canManageUsers ||
                                          vm.rowBusy[u.id] == true)
                                      ? null
                                      : () => _openUpsertDialog(vm, user: u),
                                  icon: const Icon(Icons.edit_outlined),
                                ),
                                IconButton(
                                  tooltip: 'Delete',
                                  onPressed:
                                      (!caps.canManageUsers ||
                                          vm.rowBusy[u.id] == true)
                                      ? null
                                      : () => _confirmDelete(vm, u),
                                  icon: const Icon(Icons.delete_outline),
                                ),
                                if (vm.rowBusy[u.id] == true)
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
      SnackBar(content: Text(ok ? 'Deleted.' : (vm.errorMessage ?? 'Error.'))),
    );
  }

  Future<void> _openUpsertDialog(
    ManageUsersViewModel vm, {
    ManagedUser? user,
  }) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _UpsertUserDialog(vm: vm, user: user),
    );

    if (res == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(user == null ? 'Created.' : 'Updated.')),
      );
    }
  }
}

class _UpsertUserDialog extends StatefulWidget {
  const _UpsertUserDialog({required this.vm, this.user});

  final ManageUsersViewModel vm;
  final ManagedUser? user;

  @override
  State<_UpsertUserDialog> createState() => _UpsertUserDialogState();
}

class _UpsertUserDialogState extends State<_UpsertUserDialog> {
  late final TextEditingController _emailController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late UserRole _role;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _emailController = TextEditingController(text: u?.email ?? '');
    _firstNameController = TextEditingController(text: u?.firstName ?? '');
    _lastNameController = TextEditingController(text: u?.lastName ?? '');
    _role = u?.role ?? UserRole.viewer;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final u = widget.user;
        final busy = u == null
            ? widget.vm.isLoading
            : (widget.vm.rowBusy[u.id] == true);
        return AlertDialog(
          title: Text(u == null ? 'Add user' : 'Edit user'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailController,
                  enabled: u == null && !busy,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (u != null) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _firstNameController,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'First name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _lastNameController,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'Last name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<UserRole>(
                  initialValue: _role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.homeowner,
                      child: Text('Home Owner'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.viewer,
                      child: Text('Viewer'),
                    ),
                  ],
                  onChanged: busy
                      ? null
                      : (v) {
                          if (v == null) return;
                          _role = v;
                        },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final e = _emailController.text.trim();
                      if (e.isEmpty || !e.contains('@')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid email.')),
                        );
                        return;
                      }
                      final fn = _firstNameController.text.trim();
                      final ln = _lastNameController.text.trim();
                      if (u != null && (fn.isEmpty || ln.isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'First name and last name are required.',
                            ),
                          ),
                        );
                        return;
                      }
                      final ok = u == null
                          ? await widget.vm.createUser(email: e, role: _role)
                          : await widget.vm.updateUser(
                              id: u.id,
                              firstName: fn,
                              lastName: ln,
                              role: _role,
                            );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pop(true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(widget.vm.errorMessage ?? 'Error.'),
                          ),
                        );
                      }
                    },
              child: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(u == null ? 'Add' : 'Save'),
            ),
          ],
        );
      },
    );
  }
}

class _FiltersCard extends StatelessWidget {
  const _FiltersCard({
    required this.controller,
    required this.onTermChanged,
    required this.onRefresh,
    this.onAddUser,
  });

  final TextEditingController controller;
  final ValueChanged<String> onTermChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback? onAddUser;

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
                onChanged: onTermChanged,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Email...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => onRefresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
            if (onAddUser != null)
              FilledButton.icon(
                onPressed: onAddUser,
                icon: const Icon(Icons.add),
                label: const Text('Add user'),
              ),
          ],
        ),
      ),
    );
  }
}
