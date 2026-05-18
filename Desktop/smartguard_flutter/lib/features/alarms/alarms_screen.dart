import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/alarms/data/api_alerts_repository.dart';
import 'package:smartguard_flutter/features/alarms/data/alerts_repository.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_models.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_type.dart';
import 'package:smartguard_flutter/features/alarms/viewmodel/alarms_view_model.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class AlarmsScreen extends StatefulWidget {
  const AlarmsScreen({super.key});

  @override
  State<AlarmsScreen> createState() => _AlarmsScreenState();
}

class _AlarmsScreenState extends State<AlarmsScreen> {
  AlertsRepository? _repo;
  AlarmsViewModel? _vm;

  int _tabIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = ApiAlertsRepository(api: AppScope.of(context).api);
    _vm = AlarmsViewModel(repository: _repo!);
    _vm!.addListener(_onVmChanged);
    _vm!.init();
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Center(child: AsyncStatePanel.loading());

    final theme = Theme.of(context);
    final page = vm.page;
    final selected = vm.selectedAlert;

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alarm Center',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitor and manage security alerts',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ControlsRow(
          tabIndex: _tabIndex,
          onTabChanged: (idx) async {
            _tabIndex = idx;
            setState(() {});
            await vm.setStatusFilter(_statusIdForTab(vm, idx));
          },
        ),
        const SizedBox(height: 12),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 980;
              if (wide) {
                return Row(
                  children: [
                    Expanded(child: _buildList(vm)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 380,
                      child: _DetailsPanel(
                        alert: selected,
                        statusName: selected?.alertStatus?.name,
                        typeName: selected?.alertType?.name,
                        isBusy: selected == null
                            ? false
                            : vm.rowBusy[selected.id.toString()] == true,
                        onConfirm: selected == null
                            ? null
                            : () => _confirm(vm, selected),
                        onResolve: selected == null
                            ? null
                            : () => _resolve(vm, selected),
                        onDismiss: selected == null
                            ? null
                            : () => _dismiss(vm, selected),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(child: _buildList(vm)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 360,
                    child: _DetailsPanel(
                      alert: selected,
                      statusName: selected?.alertStatus?.name,
                      typeName: selected?.alertType?.name,
                      isBusy: selected == null
                          ? false
                          : vm.rowBusy[selected.id.toString()] == true,
                      onConfirm: selected == null
                          ? null
                          : () => _confirm(vm, selected),
                      onResolve: selected == null
                          ? null
                          : () => _resolve(vm, selected),
                      onDismiss: selected == null
                          ? null
                          : () => _dismiss(vm, selected),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (page != null) ...[
          const SizedBox(height: 12),
          _Pager(
            total: page.count,
            page: vm.query.page,
            pageSize: vm.query.pageSize,
            isLoading: vm.isLoading,
            onPrev: vm.query.page > 1
                ? () => vm.changePage(vm.query.page - 1)
                : null,
            onNext: (vm.query.page * vm.query.pageSize) < page.count
                ? () => vm.changePage(vm.query.page + 1)
                : null,
            onPageSizeChanged: (size) => vm.changePageSize(size),
          ),
        ],
      ],
    );
  }

  Widget _buildList(AlarmsViewModel vm) {
    final page = vm.page;
    if (vm.isBootstrapping && page == null) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (vm.isLoading && page == null) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (vm.errorMessage != null && page == null) {
      return Center(
        child: AsyncStatePanel.error(
          errorMessage: vm.errorMessage!,
          onRetry: vm.bootstrap,
        ),
      );
    }
    if (page == null) return const SizedBox.shrink();
    if (page.result.isEmpty) {
      return Center(
        child: AsyncStatePanel.content(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No alarms.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (vm.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(vm.errorMessage!),
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: page.result.length,
            separatorBuilder: (_, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final a = page.result[index];
              final isSelected = vm.selectedAlertId == a.id;
              final statusName = a.alertStatus?.name;
              final typeName = a.alertType?.name;
              final title = a.alertType?.name?.isEmpty ?? true
                  ? (typeName ?? 'Alert')
                  : a.alertType?.name ?? '';
              final subtitle = a.device?.name?.isEmpty ?? true
                  ? _deviceFallback(a.deviceId)
                  : a.device?.name ?? '';
              return _AlertCard(
                alert: a,
                title: title,
                subtitle: subtitle,
                statusName: statusName ?? '-',
                isSelected: isSelected,
                onTap: () => vm.select(a),
              );
            },
          ),
        ),
      ],
    );
  }

  int? _statusIdForTab(AlarmsViewModel vm, int tabIndex) {
    switch (tabIndex) {
      case 0:
        return null;
      case 1:
        return vm.pendingStatusId;
      case 2:
        return vm.confirmedStatusId;
      case 3:
        return vm.resolvedStatusId;
      case 4:
        return vm.dismissedStatusId;
      default:
        return null;
    }
  }

  Future<void> _confirm(AlarmsViewModel vm, AlertRow row) async {
    final ok = await vm.confirmSelected();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Confirm failed.')),
      );
    }
  }

  Future<void> _resolve(AlarmsViewModel vm, AlertRow row) async {
    final ok = await vm.resolveSelected();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Resolve failed.')),
      );
    }
  }

  Future<void> _dismiss(AlarmsViewModel vm, AlertRow row) async {
    final reason = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _DismissDialog(),
    );
    if (!mounted) return;
    if (reason == null) return;

    final ok = await vm.dismissSelected(reason);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.errorMessage ?? 'Dismiss failed.')),
      );
    }
  }
}

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({required this.tabIndex, required this.onTabChanged});

  final int tabIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ToggleButtons(
              isSelected: [
                tabIndex == 0,
                tabIndex == 1,
                tabIndex == 2,
                tabIndex == 3,
                tabIndex == 4,
              ],
              onPressed: onTabChanged,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('All'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('Pending'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('Confirmed'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('Resolved'),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('Dismissed'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.title,
    required this.subtitle,
    required this.statusName,
    required this.isSelected,
    required this.onTap,
  });

  final AlertRow alert;
  final String title;
  final String subtitle;
  final String statusName;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = isSelected
        ? BorderSide(color: theme.colorScheme.primary, width: 1)
        : BorderSide(color: theme.dividerColor);
    final createdAt = alert.linkedEvent?.timestamp ?? DateTime.now();
    return InkWell(
      onTap: onTap,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border,
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ALM-${alert.id}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(name: statusName),
                  const SizedBox(height: 8),
                  Text(
                    createdAt == null ? '-' : _fmtDateTime(createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.name});

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

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.alert,
    required this.statusName,
    required this.typeName,
    required this.isBusy,
    required this.onConfirm,
    required this.onResolve,
    required this.onDismiss,
  });

  final AlertRow? alert;
  final String? statusName;
  final String? typeName;
  final bool isBusy;
  final VoidCallback? onConfirm;
  final VoidCallback? onResolve;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = alert;
    if (a == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'Select an alert to see details.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
      );
    }

    final status = (statusName ?? '').trim();
    final lower = status.toLowerCase();
    final canConfirm = lower.contains('pending');
    final canResolve = lower.contains('confirmed');
    final canDismiss = lower.contains('pending');

    final deviceLabel = a.device?.name?.isEmpty ?? true
        ? _deviceFallback(a.deviceId)
        : a.device?.name ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alarm', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            _kv('Alarm ID', 'ALM-${a.id}'),
            _kv(
              'Type',
              (typeName ?? '-').trim().isEmpty ? '-' : typeName ?? '',
            ),
            _kv('Status', status.isEmpty ? '-' : status),
            _kv('Device', deviceLabel),
            _kv(
              'Time',
              a.linkedEvent?.timestamp == null
                  ? '-'
                  : _fmtDateTime(a.linkedEvent?.timestamp ?? DateTime.now()),
            ),
            if (canResolve || canConfirm || canDismiss)
              Row(
                children: [
                  if (canResolve)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isBusy ? null : onResolve,
                        icon: isBusy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: const Text('Mark as Resolved'),
                      ),
                    ),
                  if (canConfirm) ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isBusy ? null : onConfirm,
                        icon: isBusy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.report_gmailerrorred_outlined),
                        label: const Text('Confirm Threat'),
                      ),
                    ),
                  ],
                  if (canDismiss) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                        ),
                        onPressed: isBusy ? null : onDismiss,
                        icon: isBusy
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.close),
                        label: const Text('Dismiss'),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 110, child: Text(k)),
          const SizedBox(width: 10),
          Expanded(child: Text(v)),
        ],
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
    return AlertDialog(
      title: const Text('Dismiss alert'),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Dismissal reason',
            hintText: 'Enter reason...',
          ),
          maxLines: 3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final t = _controller.text.trim();
            if (t.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Dismissal reason is required.')),
              );
              return;
            }
            Navigator.of(context).pop(t);
          },
          child: const Text('Dismiss'),
        ),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({
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

String _fmtDateTime(DateTime dt) {
  final y = dt.year.toString().padLeft(4, '0');
  final m = dt.month.toString().padLeft(2, '0');
  final d = dt.day.toString().padLeft(2, '0');
  final h = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  final s = dt.second.toString().padLeft(2, '0');
  return '$y-$m-$d $h:$mm:$s';
}

String _deviceFallback(int? deviceId) {
  if (deviceId == null || deviceId <= 0) return '-';
  return 'Device $deviceId';
}

Color _statusColor(BuildContext context, String name) {
  final lower = name.toLowerCase();
  if (lower.contains('pending')) return Colors.amberAccent.shade400;
  if (lower.contains('confirmed')) return Colors.redAccent.shade200;
  if (lower.contains('resolved')) return Colors.greenAccent.shade400;
  if (lower.contains('dismissed')) return Colors.blueGrey.shade300;
  return Theme.of(context).colorScheme.primary;
}
