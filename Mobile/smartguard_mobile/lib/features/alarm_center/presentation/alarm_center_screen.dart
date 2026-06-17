import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/ui/app_error_state.dart';
import '../application/alarm_center_controller.dart';
import '../application/alarm_center_state.dart';
import '../../profile/application/profile_controller.dart';
import '../../profile/domain/profile_models.dart';
import 'widgets/alarm_dismiss_dialog.dart';
import 'widgets/alarm_error_banner.dart';
import 'widgets/alarm_tile.dart';

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
              AlarmErrorBanner(message: state.errorMessage!),
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
                      child: AlarmTile(
                        alarm: alarm,
                        canAct: canAct,
                        busy: busy,
                        onConfirm: () => _showConfirmDialog(alarmId: alarm.id),
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

  Future<void> _showConfirmDialog({required int alarmId}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.alarmConfirmTitle),
          content: const Text(AppStrings.alarmConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(AppStrings.actionCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(AppStrings.alarmActionConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;
    await ref
        .read(alarmCenterControllerProvider.notifier)
        .confirm(id: alarmId);
  }

  Future<void> _showDismissDialog({required int alarmId}) async {
    final reason = await showDialog<String?>(
      context: context,
      builder: (_) => const AlarmDismissDialog(),
    );

    final value = reason?.trim();
    if (value == null || value.isEmpty) return;

    if (!mounted) return;
    await ref
        .read(alarmCenterControllerProvider.notifier)
        .dismiss(id: alarmId, dismissalReason: value);
  }
}
