import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_guard_flutter/features/profile/application/profile_controller.dart';
import 'package:smart_guard_flutter/features/profile/domain/profile_models.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/ui/app_error_state.dart';
import '../application/known_persons_controller.dart';
import '../application/known_persons_state.dart';
import 'widgets/add_known_person_dialog.dart';
import 'widgets/known_person_card.dart';
import 'widgets/known_persons_info_card.dart';

class KnownPersonsScreen extends ConsumerWidget {
  const KnownPersonsScreen({super.key});

  Future<void> _openAddDialog(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<AddKnownPersonResult>(
      context: context,
      builder: (context) => const AddKnownPersonDialog(),
    );
    if (result == null) return;

    final controller = ref.read(knownPersonsControllerProvider.notifier);
    final success = await controller.addPerson(
      firstName: result.firstName,
      lastName: result.lastName,
      photoBytes: result.photoBytes,
      photoFileName: result.photoFileName,
    );

    if (!context.mounted) return;
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Known person added.')));
    } else {
      final message =
          ref.read(knownPersonsControllerProvider).errorMessage ??
          AppStrings.errorUnknown;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String personId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete known person'),
        content: Text('Remove "$name" from known persons?'),
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
    if (confirmed != true) return;

    final controller = ref.read(knownPersonsControllerProvider.notifier);
    final success = await controller.deletePerson(personId);
    if (!context.mounted) return;
    if (!success) {
      final message =
          ref.read(knownPersonsControllerProvider).errorMessage ??
          AppStrings.errorUnknown;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(knownPersonsControllerProvider);
    final controller = ref.read(knownPersonsControllerProvider.notifier);
    final isAdmin =
        ref.watch(profileControllerProvider).profile?.role == UserRole.admin;

    if (state.status == KnownPersonsStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.refresh();
      });
    }

    return SafeArea(
      child: Scaffold(
        floatingActionButton: isAdmin
            ? FloatingActionButton(
                onPressed: () => _openAddDialog(context, ref),
                child: const Icon(Icons.person_add_alt_1),
              )
            : null,
        body: ListView(
          padding: AppDimens.pagePadding,
          children: [
            KnownPersonsInfoCard(text: AppStrings.knownPersonsInfo),
            const SizedBox(height: AppDimens.spaceM),
            if (state.status == KnownPersonsStatus.loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppDimens.spaceL),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.status == KnownPersonsStatus.error)
              AppErrorState(
                title: AppStrings.knownPersonsTitle,
                message: state.errorMessage ?? AppStrings.errorUnknown,
                onRetry: controller.refresh,
              )
            else if (state.items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppDimens.spaceL,
                ),
                child: Text(
                  AppStrings.knownPersonsEmpty,
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
              if (state.errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDimens.spaceM),
                  child: Text(
                    state.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppDimens.spaceM,
                  crossAxisSpacing: AppDimens.spaceM,
                  childAspectRatio: 0.78,
                ),
                itemCount: state.items.length,
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  final person = item.knownPerson;
                  final isUpdating = state.updatingPersonIds.contains(
                    person.id,
                  );
                  final isDeleting = state.deletingPersonIds.contains(
                    person.id,
                  );

                  return KnownPersonCard(
                    name: person.displayName,
                    pictureUrl: person.pictureUrl,
                    enabled: item.enabled,
                    isUpdating: isUpdating,
                    onToggle: (v) => controller.toggleEnabled(
                      personId: person.id,
                      enabled: v,
                    ),
                    isDeleting: isDeleting,
                    onDelete: isAdmin
                        ? () => _confirmDelete(
                            context,
                            ref,
                            person.id,
                            person.displayName,
                          )
                        : null,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
