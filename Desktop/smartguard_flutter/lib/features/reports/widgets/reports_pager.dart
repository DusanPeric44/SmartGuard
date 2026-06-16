import 'package:flutter/material.dart';

class ReportsPager extends StatelessWidget {
  const ReportsPager({
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text('Total: $total'),
            const Spacer(),
            DropdownButton<int>(
              value: pageSize,
              items: const [
                DropdownMenuItem(value: 10, child: Text('10')),
                DropdownMenuItem(value: 20, child: Text('20')),
                DropdownMenuItem(value: 50, child: Text('50')),
              ],
              onChanged: isLoading ? null : (v) => onPageSizeChanged(v ?? 10),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: isLoading ? null : onPrev,
              child: const Text('Prev'),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: isLoading ? null : onNext,
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
