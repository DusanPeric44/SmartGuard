import 'package:flutter/material.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/features/manage_users/model/managed_user.dart';
import 'package:smartguard_flutter/features/manage_users/viewmodel/manage_users_view_model.dart';

class UpsertUserDialog extends StatefulWidget {
  const UpsertUserDialog({super.key, required this.vm, this.user});

  final ManageUsersViewModel vm;
  final ManagedUser? user;

  @override
  State<UpsertUserDialog> createState() => _UpsertUserDialogState();
}

class _UpsertUserDialogState extends State<UpsertUserDialog> {
  static final RegExp _emailRegExp = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final _formKey = GlobalKey<FormState>();
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
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                TextFormField(
                  controller: _emailController,
                  enabled: u == null && !busy,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: u != null
                      ? null
                      : (value) {
                          final v = (value ?? '').trim();
                          if (v.isEmpty) return 'Email is required.';
                          if (!_emailRegExp.hasMatch(v)) {
                            return 'Enter a valid email (e.g. name@example.com).';
                          }
                          return null;
                        },
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
                  items: [
                    for (final role in UserRole.values)
                      DropdownMenuItem(
                        value: role,
                        child: Text(userRoleToWire(role)),
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
                      if (u == null &&
                          !(_formKey.currentState?.validate() ?? false)) {
                        return;
                      }
                      final e = _emailController.text.trim();
                      final fn = _firstNameController.text.trim();
                      final ln = _lastNameController.text.trim();
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
