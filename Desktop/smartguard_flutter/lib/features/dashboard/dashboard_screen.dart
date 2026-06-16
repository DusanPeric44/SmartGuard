import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/dashboard/data/api_dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/data/dashboard_repository.dart';
import 'package:smartguard_flutter/features/dashboard/viewmodel/dashboard_view_model.dart';
import 'package:smartguard_flutter/features/dashboard/widgets/dashboard_bottom_section.dart';
import 'package:smartguard_flutter/features/dashboard/widgets/dashboard_header.dart';
import 'package:smartguard_flutter/features/dashboard/widgets/dashboard_kpis_section.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardRepository? _repo;
  DashboardViewModel? _vm;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = _buildRepository();
    _vm = DashboardViewModel(repository: _repo!);
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

  DashboardRepository _buildRepository() {
    return ApiDashboardRepository(api: AppScope.of(context).api);
  }

  @override
  Widget build(BuildContext context) {
    final vm = _vm;
    if (vm == null) return const Center(child: AsyncStatePanel.loading());

    final overview = vm.overview;
    return ListView(
      children: [
        DashboardHeader(
          lastRefresh: vm.lastRefresh,
          isRefreshing: vm.isLoading,
          onRefresh: () => vm.refresh(),
        ),
        const SizedBox(height: 16),
        if (vm.isLoading && overview == null)
          const AsyncStatePanel.loading(message: 'Loading dashboard...')
        else if (vm.errorMessage != null && overview == null)
          AsyncStatePanel.error(
            errorMessage: vm.errorMessage!,
            onRetry: vm.refresh,
          )
        else if (overview == null)
          const SizedBox.shrink()
        else ...[
          if (vm.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(vm.errorMessage!),
                ),
              ),
            ),
          DashboardKpisSection(overview: overview),
          const SizedBox(height: 16),
          DashboardBottomSection(overview: overview),
        ],
      ],
    );
  }
}
