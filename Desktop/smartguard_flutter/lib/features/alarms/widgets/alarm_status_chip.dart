import 'package:flutter/material.dart';

class AlarmStatusChip extends StatelessWidget {
  const AlarmStatusChip({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(context, name);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(name),
    );
  }
}

Color _statusColor(BuildContext context, String name) {
  final lower = name.toLowerCase();
  if (lower.contains('pending')) return Colors.amberAccent.shade400;
  if (lower.contains('confirmed')) return Colors.redAccent.shade200;
  if (lower.contains('resolved')) return Colors.greenAccent.shade400;
  if (lower.contains('dismissed')) return Colors.blueGrey.shade300;
  return Theme.of(context).colorScheme.primary;
}
