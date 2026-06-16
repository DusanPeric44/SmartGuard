import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/core/auth/user_role.dart';
import 'package:smartguard_flutter/features/known_persons/data/api_known_persons_repository.dart';
import 'package:smartguard_flutter/features/known_persons/data/known_persons_repository.dart';
import 'package:smartguard_flutter/features/known_persons/model/known_person.dart';
import 'package:smartguard_flutter/features/known_persons/viewmodel/known_persons_view_model.dart';
import 'package:smartguard_flutter/features/known_persons/widgets/edit_known_person_dialog.dart';
import 'package:smartguard_flutter/features/known_persons/widgets/mergeable_known_person_card.dart';
import 'package:smartguard_flutter/shared/widgets/async_state_panel.dart';

class KnownPersonsScreen extends StatefulWidget {
  const KnownPersonsScreen({super.key});

  @override
  State<KnownPersonsScreen> createState() => _KnownPersonsScreenState();
}

class _KnownPersonsScreenState extends State<KnownPersonsScreen> {
  KnownPersonsRepository? _repo;
  KnownPersonsViewModel? _vm;
  final _searchController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_repo != null) return;

    _repo = ApiKnownPersonsRepository(api: AppScope.of(context).api);
    _vm = KnownPersonsViewModel(repository: _repo!);
    _vm!.addListener(_onVmChanged);
    _vm!.init();
  }

  @override
  void dispose() {
    _vm?.removeListener(_onVmChanged);
    _vm?.dispose();
    _searchController.dispose();
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

    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Known Persons', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Manage Face ID recognition database',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 360,
                      child: TextField(
                        controller: _searchController,
                        onChanged: vm.setTerm,
                        decoration: const InputDecoration(
                          labelText: 'Search',
                          hintText: 'Name...',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: vm.load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(child: _buildBody(vm)),
      ],
    );
  }

  Widget _buildBody(KnownPersonsViewModel vm) {
    if (vm.isLoading && vm.items.isEmpty) {
      return const Center(child: AsyncStatePanel.loading());
    }
    if (vm.errorMessage != null && vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.error(
          errorMessage: vm.errorMessage!,
          onRetry: vm.load,
        ),
      );
    }
    if (vm.items.isEmpty) {
      return Center(
        child: AsyncStatePanel.content(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No known persons.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              for (final p in vm.items)
                SizedBox(
                  width: 260,
                  child: MergeableKnownPersonCard(
                    enabled: AppScope.of(context).auth.role == UserRole.admin,
                    person: p,
                    isBusy: vm.rowBusy[p.id] == true,
                    onTap: () => context.go(
                      '/known-persons/${p.id}/detections',
                      extra: p.fullName,
                    ),
                    onEdit: () => _openEditDialog(vm, p),
                    onDelete: () => _confirmDelete(vm, p),
                    onMerge: (source, target) =>
                        _confirmMerge(vm, source, target),
                    rowBusy: vm.rowBusy,
                  ),
                ),
            ],
          ),
          if (vm.hasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: OutlinedButton(
                  onPressed: vm.isLoading ? null : vm.loadMore,
                  child: vm.isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Load more'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openEditDialog(
    KnownPersonsViewModel vm,
    KnownPerson person,
  ) async {
    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return EditKnownPersonDialog(vm: vm, person: person);
      },
    );

    if (res == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Person updated.')));
    }
  }

  Future<void> _confirmDelete(
    KnownPersonsViewModel vm,
    KnownPerson person,
  ) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove person'),
        content: Text('Remove ${person.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (res != true) return;

    final ok = await vm.deletePerson(person.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Person removed.' : (vm.errorMessage ?? 'Error.')),
      ),
    );
  }

  Future<void> _confirmMerge(
    KnownPersonsViewModel vm,
    KnownPerson source,
    KnownPerson target,
  ) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge known persons'),
        content: Text(
          'Merge ${source.fullName} into ${target.fullName}? ${source.fullName} will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm Merge'),
          ),
        ],
      ),
    );
    if (res != true) return;

    final ok = await vm.mergePersons(targetId: target.id, sourceId: source.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Persons merged.' : (vm.errorMessage ?? 'Error.')),
      ),
    );
  }
}
