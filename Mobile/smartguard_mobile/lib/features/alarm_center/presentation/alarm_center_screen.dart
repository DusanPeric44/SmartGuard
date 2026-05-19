import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/ui/app_error_state.dart';
import '../application/alarm_center_controller.dart';
import '../application/alarm_center_state.dart';
import '../domain/alarm.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/domain/profile_models.dart';

class AlarmCenterScreen extends ConsumerStatefulWidget {
  const AlarmCenterScreen({super.key});

  @override
  ConsumerState<AlarmCenterScreen> createState() => _AlarmCenterScreenState();
}

class _AlarmCenterScreenState extends ConsumerState<AlarmCenterScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (!pos.hasPixels) return;
    if (pos.maxScrollExtent - pos.pixels <= 200) {
      ref.read(alarmCenterControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alarmCenterControllerProvider);
    final controller = ref.read(alarmCenterControllerProvider.notifier);
    final profileState = ref.watch(profileControllerProvider);
    final role = profileState.profile?.role ?? UserRole.viewer;
    final canAct = role == UserRole.homeOwner;

    if (state.status == AlarmCenterStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadInitial();
      });
    }

    final showFullLoading =
        state.status == AlarmCenterStatus.loading && state.items.isEmpty;

    if (showFullLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == AlarmCenterStatus.error && state.items.isEmpty) {
      return AppErrorState(
        title: 'Failed to load alarms',
        message: state.errorMessage ?? '',
        onRetry: controller.refresh,
      );
    }

    return SafeArea(
      child: Padding(
        padding: AppDimens.pagePadding,
        child: Column(
          children: [
            if (state.errorMessage != null) ...[
              _ErrorBanner(message: state.errorMessage!),
              const SizedBox(height: AppDimens.spaceM),
            ],
            Expanded(
              child: RefreshIndicator(
                onRefresh: controller.refresh,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppDimens.spaceM,
                        ),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final alarm = state.items[index];
                    final busy = state.actingIds.contains(alarm.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppDimens.spaceM),
                      child: _AlarmTile(
                        alarm: alarm,
                        canAct: canAct,
                        busy: busy,
                        onConfirm: () => controller.confirm(id: alarm.id),
                        onDismiss: () => _showDismissDialog(alarmId: alarm.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDismissDialog({required int alarmId}) async {
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) => const _DismissDialog(),
    );

    final value = reason?.trim();
    if (value == null || value.isEmpty) return;

    if (!mounted) return;
    await ref
        .read(alarmCenterControllerProvider.notifier)
        .dismiss(id: alarmId, dismissalReason: value);
  }
}

class _AlarmTile extends StatelessWidget {
  const _AlarmTile({
    required this.alarm,
    required this.canAct,
    required this.busy,
    required this.onConfirm,
    required this.onDismiss,
  });

  final Alarm alarm;
  final bool canAct;
  final bool busy;
  final VoidCallback onConfirm;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = alarm.uiStatus;
    final showActions = canAct && status == AlarmUiStatus.pending;

    final icon = switch (status) {
      AlarmUiStatus.pending => Icons.warning_amber_rounded,
      AlarmUiStatus.confirmed => Icons.report_rounded,
      AlarmUiStatus.resolved => Icons.check_circle_rounded,
      AlarmUiStatus.unknown => Icons.notifications_outlined,
    };

    final iconColor = switch (status) {
      AlarmUiStatus.pending => Colors.amber.shade700,
      AlarmUiStatus.confirmed => scheme.error,
      AlarmUiStatus.resolved => Colors.green.shade700,
      AlarmUiStatus.unknown => scheme.onSurfaceVariant,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: AppDimens.cardRadius),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(AppDimens.spaceM),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppDimens.spaceM,
          0,
          AppDimens.spaceM,
          AppDimens.spaceM,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          alarm.title.trim().isEmpty ? 'Alarm' : alarm.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppDimens.spaceXs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (alarm.message.trim().isNotEmpty)
                Text(
                  alarm.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(height: AppDimens.spaceS),
              Text(
                _formatDate(alarm.createdAt),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        trailing: _StatusChip(status: status, statusName: alarm.statusName),
        children: [
          if (_resolveImageUrl(alarm.linkedEventImagePath) case final u?)
            ClipRRect(
              borderRadius: AppDimens.cardRadius,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  u,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: scheme.surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: scheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
              ),
            ),
          if (showActions) ...[
            const SizedBox(height: AppDimens.spaceM),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : onConfirm,
                    child: const Text('Confirm'),
                  ),
                ),
                const SizedBox(width: AppDimens.spaceM),
                Expanded(
                  child: OutlinedButton(
                    onPressed: busy ? null : onDismiss,
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static String? _resolveImageUrl(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;

    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;

    final base = Uri.parse(AppConfig.apiBaseUrl);
    return base.resolve(value).toString();
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final d = dt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[d.month - 1];
    final day = d.day.toString().padLeft(2, '0');
    final year = d.year.toString();

    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final hour = hour12.toString().padLeft(2, '0');
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '$month $day, $year $hour:$minute $ampm';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.statusName});

  final AlarmUiStatus status;
  final String? statusName;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final label = switch (status) {
      AlarmUiStatus.pending => 'Pending',
      AlarmUiStatus.confirmed => 'Confirmed',
      AlarmUiStatus.resolved => 'Resolved',
      AlarmUiStatus.unknown =>
        (statusName?.trim().isNotEmpty ?? false)
            ? statusName!.trim()
            : 'Unknown',
    };

    final (border, fg, bg) = switch (status) {
      AlarmUiStatus.pending => (
        Colors.amber.shade700,
        Colors.amber.shade900,
        Colors.amber.shade50,
      ),
      AlarmUiStatus.confirmed => (
        scheme.error,
        scheme.error,
        Colors.transparent,
      ),
      AlarmUiStatus.resolved => (
        Colors.green.shade700,
        Colors.green.shade700,
        Colors.green.shade50,
      ),
      AlarmUiStatus.unknown => (
        scheme.outline,
        scheme.onSurfaceVariant,
        Colors.transparent,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.spaceM,
        vertical: AppDimens.spaceS,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.pillRadius),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimens.spaceM),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppDimens.cardRadius,
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
      ),
    );
  }
}

class _DismissDialog extends StatefulWidget {
  const _DismissDialog();

  @override
  State<_DismissDialog> createState() => _DismissDialogState();
}

class _DismissDialogState extends State<_DismissDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _controller.text.trim();
    return AlertDialog(
      title: const Text('Dismiss alarm'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Dismissal reason'),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: value.isEmpty
              ? null
              : () => Navigator.of(context).pop(value),
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}
