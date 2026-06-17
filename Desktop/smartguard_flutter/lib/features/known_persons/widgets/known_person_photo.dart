import 'package:flutter/material.dart';

class KnownPersonPhoto extends StatelessWidget {
  const KnownPersonPhoto({
    super.key,
    required this.photoUrl,
    required this.badgeText,
    required this.badgeColor,
  });

  final String photoUrl;
  final String badgeText;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final image = photoUrl.trim().isEmpty
        ? CircleAvatar()
        : Image.network(
            photoUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 160,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: double.infinity,
                height: 160,
                child: Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes == null
                          ? null
                          : (progress.cumulativeBytesLoaded /
                                    (progress.expectedTotalBytes ?? 1))
                                .clamp(0.0, 1.0),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/images/empty-avatar.png');
            },
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          SizedBox(width: double.infinity, height: 160, child: image),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeColor.withValues(alpha: 0.55)),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
