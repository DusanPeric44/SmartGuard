import 'package:flutter/material.dart';
import 'package:smartguard_flutter/features/audit_logs/widgets/audit_logs_format.dart';

class AuditLogsFiltersCard extends StatelessWidget {
  const AuditLogsFiltersCard({
    super.key,
    required this.searchController,
    required this.selectedRange,
    required this.selectedUser,
    required this.selectedAction,
    required this.selectedResource,
    required this.selectedStatus,
    required this.userOptions,
    required this.actionOptions,
    required this.resourceOptions,
    required this.statusOptions,
    required this.onSearchChanged,
    required this.onPickRange,
    required this.onUserChanged,
    required this.onActionChanged,
    required this.onResourceChanged,
    required this.onStatusChanged,
    required this.onReset,
  });

  final TextEditingController searchController;
  final DateTimeRange? selectedRange;

  final String? selectedUser;
  final String? selectedAction;
  final String? selectedResource;
  final String? selectedStatus;

  final List<String> userOptions;
  final List<String> actionOptions;
  final List<String> resourceOptions;
  final List<String> statusOptions;

  final ValueChanged<String> onSearchChanged;
  final VoidCallback onPickRange;
  final ValueChanged<String?> onUserChanged;
  final ValueChanged<String?> onActionChanged;
  final ValueChanged<String?> onResourceChanged;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final users = _optionsWithSelected(userOptions, selectedUser);
    final actions = _optionsWithSelected(actionOptions, selectedAction);
    final resources = _optionsWithSelected(resourceOptions, selectedResource);
    final statuses = _optionsWithSelected(statusOptions, selectedStatus);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 500,
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  labelText: 'Search',
                  hintText: 'Text...',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            SizedBox(
              width: 280,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedUser,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All users'),
                  ),
                  for (final u in users)
                    DropdownMenuItem<String?>(
                      value: u,
                      child: Text(
                        u,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: onUserChanged,
                decoration: const InputDecoration(labelText: 'User'),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedAction,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All actions'),
                  ),
                  for (final a in actions)
                    DropdownMenuItem<String?>(
                      value: a,
                      child: Text(
                        a,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: onActionChanged,
                decoration: const InputDecoration(labelText: 'Action'),
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedResource,
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All resources'),
                  ),
                  for (final r in resources)
                    DropdownMenuItem<String?>(
                      value: r,
                      child: Text(
                        r,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: onResourceChanged,
                decoration: const InputDecoration(labelText: 'Resource'),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<String?>(
                initialValue: selectedStatus,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All statuses'),
                  ),
                  for (final s in statuses)
                    DropdownMenuItem<String?>(
                      value: s,
                      child: Text(
                        s,
                        style: const TextStyle(overflow: TextOverflow.ellipsis),
                      ),
                    ),
                ],
                onChanged: onStatusChanged,
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onPickRange,
              icon: const Icon(Icons.date_range),
              label: Text(_rangeLabel(selectedRange) ?? 'Date range'),
            ),
            TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.refresh),
              label: Text('Reset', style: theme.textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}

String? _rangeLabel(DateTimeRange? range) {
  if (range == null) return null;
  final s = yyyyMmDd(range.start);
  final e = yyyyMmDd(range.end);
  return '$s → $e';
}

List<String> _optionsWithSelected(List<String> options, String? selected) {
  final s = selected?.trim();
  if (s == null || s.isEmpty) return options;
  if (options.contains(s)) return options;
  return <String>[s, ...options];
}
