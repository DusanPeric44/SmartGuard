import 'package:flutter/material.dart';

class RecordingThumbnail extends StatelessWidget {
  const RecordingThumbnail({super.key, required this.durationLabel});

  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.asset(
            'assets/images/video-thumbnail.png',
            width: 92,
            height: 72,
            fit: BoxFit.cover,
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                durationLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
