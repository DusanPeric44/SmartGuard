import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_dimens.dart';
import '../application/recording_archive_controller.dart';
import '../application/recording_archive_state.dart';
import '../domain/recording.dart';
import 'widgets/recording_card.dart';
import 'widgets/recording_details_sheet.dart';
import 'widgets/recording_error_banner.dart';

class RecordingArchiveScreen extends ConsumerStatefulWidget {
  const RecordingArchiveScreen({super.key});

  @override
  ConsumerState<RecordingArchiveScreen> createState() =>
      _RecordingArchiveScreenState();
}

class _RecordingArchiveScreenState
    extends ConsumerState<RecordingArchiveScreen> {
  final ScrollController _scrollController = ScrollController();

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
    final position = _scrollController.position;
    if (!position.hasPixels || !position.hasContentDimensions) return;
    final threshold = position.maxScrollExtent - 200;
    if (position.pixels >= threshold) {
      ref.read(recordingArchiveControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recordingArchiveControllerProvider);
    final controller = ref.read(recordingArchiveControllerProvider.notifier);

    if (state.status == RecordingArchiveStatus.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadInitial();
      });
    }

    final itemCount = state.items.length + (state.isLoadingMore ? 1 : 0);

    return SafeArea(
      child: Column(
        children: [
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimens.spaceM,
                AppDimens.spaceM,
                AppDimens.spaceM,
                0,
              ),
              child: RecordingErrorBanner(message: state.errorMessage!),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView.builder(
                controller: _scrollController,
                padding: AppDimens.pagePadding,
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppDimens.spaceL),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final recording = state.items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppDimens.spaceM),
                    child: RecordingCard(
                      recording: recording,
                      onTap: () => _showDetails(context, recording),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDetails(BuildContext context, Recording recording) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RecordingDetailsSheet(recording: recording),
    );
  }
}
