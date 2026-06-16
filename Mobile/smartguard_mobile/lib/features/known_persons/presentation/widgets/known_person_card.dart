import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_strings.dart';
import 'known_person_photo.dart';

class KnownPersonCard extends StatelessWidget {
  const KnownPersonCard({
    super.key,
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
            Expanded(child: KnownPersonPhoto(url: pictureUrl)),
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
