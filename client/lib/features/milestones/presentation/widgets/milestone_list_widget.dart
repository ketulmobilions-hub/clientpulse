import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/providers/milestone_provider.dart';
import 'milestone_tile.dart';

class MilestoneListWidget extends ConsumerWidget {
  const MilestoneListWidget({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(milestoneNotifierProvider(projectId));
    // Root Column with Expanded list + fixed-height footer.
    // Requires bounded height from parent (e.g. TabBarView slot).
    return Column(
      children: [
        Expanded(
          child: milestonesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Failed to load milestones',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref
                        .read(milestoneNotifierProvider(projectId).notifier)
                        .load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (milestones) => milestones.isEmpty
                ? const Center(child: Text('No milestones yet'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: milestones.length,
                    onReorder: (oldIndex, newIndex) => ref
                        .read(milestoneNotifierProvider(projectId).notifier)
                        .reorder(oldIndex, newIndex),
                    itemBuilder: (_, i) => MilestoneTile(
                      key: ValueKey(milestones[i].id),
                      milestone: milestones[i],
                      projectId: projectId,
                    ),
                  ),
          ),
        ),
        if (milestonesAsync.hasValue) _AddMilestoneButton(projectId: projectId),
      ],
    );
  }
}

class _AddMilestoneButton extends ConsumerStatefulWidget {
  const _AddMilestoneButton({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_AddMilestoneButton> createState() =>
      _AddMilestoneButtonState();
}

class _AddMilestoneButtonState extends ConsumerState<_AddMilestoneButton> {
  bool _expanded = false;
  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final title = _ctrl.text.trim();
    if (title.isEmpty) {
      setState(() => _expanded = false);
      return;
    }
    // Collapse UI immediately; restore input on failure so user doesn't lose typed text.
    _ctrl.clear();
    setState(() => _expanded = false);
    _create(title);
  }

  Future<void> _create(String title) async {
    try {
      await ref
          .read(milestoneNotifierProvider(widget.projectId).notifier)
          .create(title);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$e')));
        _ctrl.text = title;
        setState(() => _expanded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_expanded) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Milestone title',
                  isDense: true,
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(onPressed: _submit, child: const Text('Add')),
            const SizedBox(width: 4),
            TextButton(
              onPressed: () {
                _ctrl.clear();
                setState(() => _expanded = false);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: TextButton.icon(
        onPressed: () {
          setState(() => _expanded = true);
        },
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add milestone'),
      ),
    );
  }
}
