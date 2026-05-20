import 'package:flutter/material.dart';
import 'package:smartguard_flutter/app/app_scope.dart';
import 'package:smartguard_flutter/features/known_persons/data/api_known_persons_repository.dart';
import 'package:smartguard_flutter/features/known_persons/data/known_persons_repository.dart';
import 'package:smartguard_flutter/features/known_persons/model/known_person.dart';
import 'package:smartguard_flutter/features/known_persons/viewmodel/known_persons_view_model.dart';
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
                  child: _KnownPersonCard(
                    person: p,
                    isBusy: vm.rowBusy[p.id] == true,
                    onEdit: () => _openEditDialog(vm, p),
                    onDelete: () => _confirmDelete(vm, p),
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
        return _EditKnownPersonDialog(vm: vm, person: person);
      },
    );

    if (res == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Updated.')));
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
      SnackBar(content: Text(ok ? 'Removed.' : (vm.errorMessage ?? 'Error.'))),
    );
  }
}

class _KnownPersonCard extends StatelessWidget {
  const _KnownPersonCard({
    required this.person,
    required this.isBusy,
    required this.onEdit,
    required this.onDelete,
  });

  final KnownPerson person;
  final bool isBusy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final badgeColor = person.isIntruder
        ? Colors.redAccent.shade400
        : Colors.greenAccent.shade400;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Photo(
              photoUrl:
                  AppScope.of(context).api.baseUri.toString() + person.picture,
              badgeText: person.isIntruder ? 'Intruder' : 'Known',
              badgeColor: badgeColor,
            ),
            const SizedBox(height: 12),
            Text(
              person.fullName,
              style: Theme.of(context).textTheme.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetaRow(
                    label: 'Location',
                    value: person.location,
                    valueColor: null,
                  ),
                ),
                const SizedBox(width: 12),
                _MetaRow(
                  label: 'Detections',
                  value: '${person.detectionCount}',
                  valueColor: Colors.lightBlueAccent.shade400,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: isBusy ? null : onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: isBusy ? null : onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove'),
                  ),
                ),
              ],
            ),
            if (isBusy) ...[
              const SizedBox(height: 10),
              const Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: valueColor),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({
    required this.photoUrl,
    required this.badgeText,
    required this.badgeColor,
  });

  final String photoUrl;
  final String badgeText;
  final Color badgeColor;

  @override
  Widget build(BuildContext context) {
    final image = photoUrl.trim().isEmpty
        ? CircleAvatar()
        : Image.network(
            photoUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: 160,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                width: double.infinity,
                height: 160,
                child: Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: progress.expectedTotalBytes == null
                          ? null
                          : (progress.cumulativeBytesLoaded /
                                    (progress.expectedTotalBytes ?? 1))
                                .clamp(0.0, 1.0),
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/images/empty-avatar.png');
            },
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          SizedBox(width: double.infinity, height: 160, child: image),
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: badgeColor.withValues(alpha: 0.55)),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditKnownPersonDialog extends StatefulWidget {
  const _EditKnownPersonDialog({required this.vm, required this.person});

  final KnownPersonsViewModel vm;
  final KnownPerson person;

  @override
  State<_EditKnownPersonDialog> createState() => _EditKnownPersonDialogState();
}

class _EditKnownPersonDialogState extends State<_EditKnownPersonDialog> {
  late final TextEditingController _first = TextEditingController(
    text: widget.person.firstName,
  );
  late final TextEditingController _last = TextEditingController(
    text: widget.person.lastName,
  );

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm,
      builder: (context, _) {
        final busy = widget.vm.rowBusy[widget.person.id] == true;
        return AlertDialog(
          title: const Text('Edit person'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _first,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'First name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _last,
                  enabled: !busy,
                  decoration: const InputDecoration(
                    labelText: 'Last name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final f = _first.text.trim();
                      final l = _last.text.trim();
                      if (f.isEmpty || l.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('First and last name are required.'),
                          ),
                        );
                        return;
                      }
                      final ok = await widget.vm.updatePerson(
                        id: widget.person.id,
                        firstName: f,
                        lastName: l,
                      );
                      if (!context.mounted) return;
                      if (ok) {
                        Navigator.of(context).pop(true);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(widget.vm.errorMessage ?? 'Error.'),
                          ),
                        );
                      }
                    },
              child: busy
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
