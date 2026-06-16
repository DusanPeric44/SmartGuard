import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/known_persons/model/known_person.dart';
import 'package:smartguard_flutter/features/known_persons/widgets/known_person_card.dart';

class MergeableKnownPersonCard extends StatelessWidget {
  const MergeableKnownPersonCard({
    super.key,
    required this.enabled,
    required this.person,
    required this.isBusy,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onMerge,
    required this.rowBusy,
  });

  final bool enabled;
  final KnownPerson person;
  final bool isBusy;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(KnownPerson source, KnownPerson target) onMerge;
  final Map<String, bool> rowBusy;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return KnownPersonCard(
        person: person,
        isBusy: isBusy,
        onTap: onTap,
        onEdit: onEdit,
        onDelete: onDelete,
      );
    }

    return DragTarget<KnownPerson>(
      onWillAcceptWithDetails: (details) {
        final source = details.data;
        if (source.id == person.id) return false;
        if (rowBusy[person.id] == true) return false;
        if (rowBusy[source.id] == true) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        onMerge(details.data, person);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          child: Draggable<KnownPerson>(
            data: person,
            feedback: SizedBox(
              width: 260,
              child: Material(
                type: MaterialType.transparency,
                child: Opacity(
                  opacity: 0.92,
                  child: KnownPersonCard(
                    person: person,
                    isBusy: false,
                    onTap: null,
                    onEdit: () {},
                    onDelete: () {},
                  ),
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: KnownPersonCard(
                person: person,
                isBusy: isBusy,
                onTap: onTap,
                onEdit: onEdit,
                onDelete: onDelete,
              ),
            ),
            child: KnownPersonCard(
              person: person,
              isBusy: isBusy,
              onTap: onTap,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
          ),
        );
      },
    );
  }
}
