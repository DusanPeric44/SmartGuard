import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/alarms/data/api_alerts_repository.dart';
import 'package:smartguard_flutter/features/alarms/data/alerts_repository.dart';
import 'package:smartguard_flutter/features/alarms/model/alert_models.dart';
import 'package:smartguard_flutter/features/alarms/viewmodel/alarms_view_model.dart';
import 'package:smartguard_flutter/features/alarms/widgets/alarm_details_panel.dart';
import 'package:smartguard_flutter/features/alarms/widgets/alarms_controls_row.dart';
import 'package:smartguard_flutter/features/alarms/widgets/alarms_dismiss_dialog.dart';
import 'package:smartguard_flutter/features/alarms/widgets/alarms_format.dart';
import 'package:smartguard_flutter/features/alarms/widgets/alarms_pager.dart';
import 'package:smartguard_flutter/features/alarms/widgets/alert_row_card.dart';
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
        AlarmsControlsRow(
          tabIndex: _tabIndex,
          onTabChanged: (idx) async {
            _tabIndex = idx;
            setState(() {});
            await vm.setStatusFilter(_statusNameForTab(idx));
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
                      child: AlarmDetailsPanel(
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
                    child: AlarmDetailsPanel(
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
          AlarmsPager(
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
                  ? deviceFallback(a.deviceId)
                  : a.device?.name ?? '';
              return AlertRowCard(
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

  String? _statusNameForTab(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return null;
      case 1:
        return 'Pending';
      case 2:
        return 'Confirmed';
      case 3:
        return 'Resolved';
      case 4:
        return 'Dismissed';
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
      builder: (context) => const AlarmsDismissDialog(),
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
