import 'package:flutter/material.dart';
import '../../../../core/constants/app_dimens.dart';

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({super.key, required this.title, required this.child});

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
