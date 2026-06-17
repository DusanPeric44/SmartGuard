import 'package:flutter/material.dart';

import '../../../../core/constants/app_dimens.dart';

class RecordingVideoUnavailable extends StatelessWidget {
  const RecordingVideoUnavailable({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AppDimens.spaceM),
      child: Text(message, textAlign: TextAlign.center),
    );
  }
}
