import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/ui/app_error_state.dart';
import '../application/known_persons_controller.dart';
import '../application/known_persons_state.dart';

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
          Text(
            AppStrings.knownPersonsTitle,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppDimens.spaceM),
          _InfoCard(text: AppStrings.knownPersonsInfo),
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

                return _KnownPersonCard(
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppDimens.cardRadius,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppDimens.spaceM),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}

class _KnownPersonCard extends StatelessWidget {
  const _KnownPersonCard({
    required this.name,
    required this.pictureUrl,
    required this.enabled,
    required this.isUpdating,
    required this.onToggle,
  });

  final String name;
  final String? pictureUrl;
  final bool enabled;
  final bool isUpdating;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: AppDimens.cardRadius,
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: AppDimens.cardRadius,
        child: Column(
          children: [
            Expanded(child: _Photo(url: pictureUrl)),
            Padding(
              padding: const EdgeInsets.all(AppDimens.spaceM),
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimens.spaceM,
                vertical: AppDimens.spaceS,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.knownPersonsNotificationsLabel,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  if (isUpdating)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch.adaptive(
                      value: enabled,
                      onChanged: isUpdating ? null : onToggle,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = _resolveImageUrl(url);
    if (u == null || u.isEmpty) {
      return Container(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: Icon(
          Icons.person,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Image.network(
      u,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          alignment: Alignment.center,
          child: Icon(
            Icons.person,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }

  String? _resolveImageUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.resolve(value).toString();
  }
}
