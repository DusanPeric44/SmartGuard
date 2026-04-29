import 'package:flutter/material.dart';
import 'package:smartguard_flutter/shared/widgets/cached_base64_image.dart';

class KnownPersonsScreen extends StatelessWidget {
  const KnownPersonsScreen({super.key});

  static const _sampleAvatarBase64 =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9WnHCqQAAAAASUVORK5CYII=';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Known Persons',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Primjer shared widget-a koji dekodira base64 jednom i kešira rezultat van build() metode.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                const _PersonTile(
                  name: 'John Carter',
                  role: 'Security Lead',
                  base64Value: _sampleAvatarBase64,
                ),
                const SizedBox(height: 12),
                const _PersonTile(
                  name: 'Amira Hadzic',
                  role: 'Operator',
                  base64Value: _sampleAvatarBase64,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  const _PersonTile({
    required this.name,
    required this.role,
    required this.base64Value,
  });

  final String name;
  final String role;
  final String base64Value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CachedBase64Image(
            base64Value: base64Value,
            width: 56,
            height: 56,
            borderRadius: 16,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(role),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
