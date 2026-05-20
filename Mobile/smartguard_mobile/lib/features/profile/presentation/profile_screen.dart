import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/ui/app_loading_overlay.dart';
import '../application/profile_controller.dart';
import '../application/profile_state.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.showHeader = true});

  final bool showHeader;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(profileControllerProvider, (previous, next) {
      if (previous?.profile != next.profile) {
        if (next.profile == null) {
          _firstNameController.text = '';
          _lastNameController.text = '';
          _emailController.text = '';
          return;
        }
        _firstNameController.text = next.firstName;
        _lastNameController.text = next.lastName;
        _emailController.text = next.email;
      }
    });

    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    if (state.status == ProfileStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.load();
      });
    }

    return SafeArea(
      child: AppLoadingOverlay(
        isLoading: state.isLoading || state.isSaving,
        child: Scaffold(
          appBar: AppBar(title: const Text(AppStrings.profileTitle)),
          body: ListView(
            padding: AppDimens.pagePadding,
            children: [
              if (widget.showHeader) ...[
                Text(
                  AppStrings.profileTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppDimens.spaceM),
              ],
              if (state.errorMessage != null) ...[
                _ErrorBanner(message: state.errorMessage!),
                const SizedBox(height: AppDimens.spaceM),
              ],
              _SectionCard(
                title: AppStrings.profileSectionAccount,
                child: state.isEditing
                    ? Column(
                        children: [
                          TextField(
                            controller: _firstNameController,
                            onChanged: controller.setFirstName,
                            decoration: const InputDecoration(
                              labelText: AppStrings.firstNameLabel,
                            ),
                          ),
                          const SizedBox(height: AppDimens.spaceM),
                          TextField(
                            controller: _lastNameController,
                            onChanged: controller.setLastName,
                            decoration: const InputDecoration(
                              labelText: AppStrings.lastNameLabel,
                            ),
                          ),
                          const SizedBox(height: AppDimens.spaceM),
                          TextField(
                            controller: _emailController,
                            enabled: false,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: AppStrings.emailLabel,
                            ),
                          ),
                          const SizedBox(height: AppDimens.spaceM),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: controller.cancelEditing,
                                  child: const Text(AppStrings.actionCancel),
                                ),
                              ),
                              const SizedBox(width: AppDimens.spaceM),
                              Expanded(
                                child: FilledButton(
                                  onPressed: state.canSave
                                      ? controller.saveProfile
                                      : null,
                                  child: const Text(AppStrings.actionSave),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppStrings.profileNamePrefix}: ${state.profile?.fullName ?? '-'}',
                          ),
                          const SizedBox(height: AppDimens.spaceS),
                          Text(
                            '${AppStrings.profileEmailPrefix}: ${state.profile?.email ?? '-'}',
                          ),
                          const SizedBox(height: AppDimens.spaceS),
                          Text(
                            '${AppStrings.profileUsernamePrefix}: ${state.profile?.username ?? '-'}',
                          ),
                          const SizedBox(height: AppDimens.spaceM),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: state.profile == null
                                  ? null
                                  : controller.startEditing,
                              child: const Text(AppStrings.profileEdit),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: AppDimens.spaceM),
              _SectionCard(
                title: AppStrings.profileSectionSecurity,
                child: ListTile(
                  title: const Text(AppStrings.profileChangePassword),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showChangePasswordDialog(context, controller),
                ),
              ),
              const SizedBox(height: AppDimens.spaceM),
              _SectionCard(
                title: AppStrings.profileSectionSession,
                child: ListTile(
                  title: const Text(AppStrings.logout),
                  trailing: const Icon(Icons.logout),
                  onTap: () => _confirmLogout(context, controller),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmLogout(
  BuildContext context,
  ProfileController controller,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text(AppStrings.logout),
        content: const Text(AppStrings.logoutConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(AppStrings.logout),
          ),
        ],
      );
    },
  );
  if (result == true) {
    await controller.logout();
  }
}

Future<void> _showChangePasswordDialog(
  BuildContext context,
  ProfileController controller,
) async {
  final currentController = TextEditingController();
  final newController = TextEditingController();
  final confirmController = TextEditingController();

  String? errorText;

  Future<void> submit(StateSetter setState) async {
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
      await controller.changePassword(
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

  await showDialog<void>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
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
                onPressed: () => submit(setState),
                child: const Text(AppStrings.actionSave),
              ),
            ],
          );
        },
      );
    },
  );

  currentController.dispose();
  newController.dispose();
  confirmController.dispose();
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppDimens.spaceS),
            child,
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: AppDimens.cardRadius,
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceM),
        child: Text(
          message,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ),
    );
  }
}
