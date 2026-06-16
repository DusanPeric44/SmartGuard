import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/ui/app_error_state.dart';
import '../application/known_persons_controller.dart';
import '../application/known_persons_state.dart';
import 'widgets/known_person_card.dart';
import 'widgets/known_persons_info_card.dart';

class KnownPersonsScreen extends ConsumerWidget {
  const KnownPersonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(knownPersonsControllerProvider);
    final controller = ref.read(knownPersonsControllerProvider.notifier);

    if (state.status == KnownPersonsStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.refresh();
      });
    }

    return SafeArea(
      child: ListView(
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
              padding: const EdgeInsets.symmetric(vertical: AppDimens.spaceL),
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
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
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
                final isUpdating = state.updatingPersonIds.contains(person.id);

                return KnownPersonCard(
                  name: person.displayName,
                  pictureUrl: person.pictureUrl,
                  enabled: item.enabled,
                  isUpdating: isUpdating,
                  onToggle: (v) =>
                      controller.toggleEnabled(personId: person.id, enabled: v),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
