import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/known_persons/model/known_person.dart';
import 'package:smartguard_flutter/features/known_persons/widgets/known_person_meta_row.dart';
import 'package:smartguard_flutter/features/known_persons/widgets/known_person_photo.dart';

class KnownPersonCard extends StatelessWidget {
  const KnownPersonCard({
    super.key,
    required this.person,
    required this.isBusy,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final KnownPerson person;
  final bool isBusy;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final badgeColor = person.isIntruder
        ? Colors.redAccent.shade400
        : Colors.greenAccent.shade400;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KnownPersonPhoto(
                photoUrl:
                    AppScope.of(context).api.baseUri.toString() + person.picture,
                badgeText: person.isIntruder ? 'Intruder' : 'Known',
                badgeColor: badgeColor,
              ),
              const SizedBox(height: 12),
              Text(
                person.fullName,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              KnownPersonMetaRow(
                label: 'Detections',
                value: '${person.detectionCount}',
                valueColor: Colors.lightBlueAccent.shade400,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: isBusy ? null : onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.outlined(
                    visualDensity: VisualDensity.compact,
                    onPressed: isBusy ? null : onDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
              if (isBusy) ...[
                const SizedBox(height: 10),
                const Center(
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
