import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';

class DashboardQuickAccessCard extends StatelessWidget {
  const DashboardQuickAccessCard({
    super.key,
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 180,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: scheme.surfaceContainerHighest,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.videocam_outlined,
                    size: 48,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppDimens.spaceM),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
