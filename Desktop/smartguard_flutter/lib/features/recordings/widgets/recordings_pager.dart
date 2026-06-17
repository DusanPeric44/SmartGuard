import 'package:flutter/material.dart';

class RecordingsPager extends StatelessWidget {
  const RecordingsPager({
    super.key,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.isLoading,
    required this.onPrev,
    required this.onNext,
    required this.onPageSizeChanged,
  });

  final int total;
  final int page;
  final int pageSize;
  final bool isLoading;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final start = total == 0 ? 0 : ((page - 1) * pageSize) + 1;
    final end = (page * pageSize).clamp(0, total);
    return Row(
      children: [
        Text('Showing $start-$end of $total'),
        const Spacer(),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<int>(
            initialValue: pageSize,
            items: const [
              DropdownMenuItem(value: 10, child: Text('10 / page')),
              DropdownMenuItem(value: 25, child: Text('25 / page')),
              DropdownMenuItem(value: 50, child: Text('50 / page')),
              DropdownMenuItem(value: 100, child: Text('100 / page')),
            ],
            onChanged: isLoading
                ? null
                : (v) => v == null ? null : onPageSizeChanged(v),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          tooltip: 'Previous',
          onPressed: isLoading ? null : onPrev,
          icon: const Icon(Icons.chevron_left),
        ),
        Text('$page'),
        IconButton(
          tooltip: 'Next',
          onPressed: isLoading ? null : onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
