import 'package:flutter/material.dart';
import 'package:smartguard_flutter/core/widgets/authenticated_network_image.dart';

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
        : AuthenticatedNetworkImage(
            url: photoUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 160,
            errorWidget: Image.asset('assets/images/empty-avatar.png'),
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
