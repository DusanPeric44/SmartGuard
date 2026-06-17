import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/reference_data/model/reference_entity.dart';

/// Chip row that selects which reference table is being managed.
class ReferenceEntitySelector extends StatelessWidget {
  const ReferenceEntitySelector({
    super.key,
    required this.selected,
    required this.onSelected,
    this.enabled = true,
  });

  final ReferenceEntity selected;
  final ValueChanged<ReferenceEntity> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entity in referenceEntities)
              ChoiceChip(
                label: Text(entity.title),
                selected: entity.id == selected.id,
                onSelected: enabled
                    ? (value) {
                        if (value) onSelected(entity);
                      }
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
