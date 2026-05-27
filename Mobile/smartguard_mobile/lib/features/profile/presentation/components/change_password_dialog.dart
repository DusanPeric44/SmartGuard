import 'package:flutter/material.dart';
import 'package:smart_guard_flutter/core/constants/app_dimens.dart';
import 'package:smart_guard_flutter/core/constants/app_strings.dart';
import 'package:smart_guard_flutter/features/profile/application/profile_controller.dart';

class ChangePasswordDialog extends StatefulWidget {
  final ProfileController controller;

  const ChangePasswordDialog({super.key, required this.controller});

  @override
  ChangePasswordDialogState createState() => ChangePasswordDialogState();
}

class ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  String? errorText;

  Future<void> _submit(StateSetter setState) async {
    final current = currentController.text;
    final next = newController.text;
    final confirm = confirmController.text;

    if (current.trim().isEmpty ||
        next.trim().isEmpty ||
        confirm.trim().isEmpty) {
      setState(() => errorText = AppStrings.validationRequired);
      return;
    }
    if (next != confirm) {
      setState(() => errorText = AppStrings.validationPasswordsDoNotMatch);
      return;
    }
    setState(() => errorText = null);
    try {
      await widget.controller.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      if (context.mounted) Navigator.of(context).pop();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.passwordUpdated)),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AppStrings.errorUnknown)));
      }
    }
  }

  @override
  void dispose() {
    currentController.dispose();
    newController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.profileChangePassword),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currentController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: AppStrings.currentPasswordLabel,
            ),
          ),
          const SizedBox(height: AppDimens.spaceM),
          TextField(
            controller: newController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: AppStrings.newPasswordLabel,
            ),
          ),
          const SizedBox(height: AppDimens.spaceM),
          TextField(
            controller: confirmController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: AppStrings.confirmNewPasswordLabel,
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: AppDimens.spaceM),
            Text(
              errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.actionCancel),
        ),
        FilledButton(
          onPressed: () async => await _submit(setState),
          child: const Text(AppStrings.actionSave),
        ),
      ],
    );
  }
}
