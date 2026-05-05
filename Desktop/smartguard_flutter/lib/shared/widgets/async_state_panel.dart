import 'package:flutter/material.dart';

class AsyncStatePanel extends StatelessWidget {
  const AsyncStatePanel.loading({
    super.key,
    this.message = 'Učitavanje...',
  })  : errorMessage = null,
        onRetry = null,
        child = null;

  const AsyncStatePanel.error({
    super.key,
    required this.errorMessage,
    this.onRetry,
  })  : message = null,
        child = null;

  const AsyncStatePanel.content({
    super.key,
    required this.child,
  })  : message = null,
        errorMessage = null,
        onRetry = null;

  final String? message;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return child!;
    }

    final theme = Theme.of(context);
    if (errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Greška',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(errorMessage!),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: onRetry,
                  child: const Text('Pokušaj ponovo'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Text(message ?? 'Učitavanje...'),
          ],
        ),
      ),
    );
  }
}
