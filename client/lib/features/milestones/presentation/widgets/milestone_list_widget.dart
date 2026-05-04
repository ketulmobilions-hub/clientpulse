import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/providers/milestone_provider.dart';
import 'package:clientpulse/shared/widgets/empty_state_widget.dart';
import 'package:clientpulse/shared/widgets/error_state_widget.dart';
import 'package:clientpulse/shared/widgets/shimmer_card.dart';
import 'milestone_tile.dart';

class MilestoneListWidget extends ConsumerWidget {
  const MilestoneListWidget({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(milestoneNotifierProvider(projectId));
    return Column(
      children: [
        Expanded(
          child: milestonesAsync.when(
            loading: () => ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, __) => const ShimmerCard(height: 60),
            ),
            error: (e, _) => ErrorStateWidget(
              message: 'Failed to load milestones',
              onRetry: () =>
                  ref.read(milestoneNotifierProvider(projectId).notifier).load(),
            ),
            data: (milestones) {
              if (milestones.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.flag_outlined,
                  message: 'No milestones yet',
                );
              }
              final firstIncompleteIdx = milestones.indexWhere((m) => !m.completed);
              return ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: milestones.length,
                onReorder: (oldIndex, newIndex) => ref
                    .read(milestoneNotifierProvider(projectId).notifier)
                    .reorder(oldIndex, newIndex),
                itemBuilder: (_, i) => MilestoneTile(
                  key: ValueKey(milestones[i].id),
                  milestone: milestones[i],
                  projectId: projectId,
                  displayIndex: i + 1,
                  isCurrentMilestone: i == firstIncompleteIdx,
                ),
              );
            },
          ),
        ),
        if (milestonesAsync.hasValue && !milestonesAsync.hasError)
          _AddMilestoneButton(projectId: projectId),
      ],
    );
  }
}

class _AddMilestoneButton extends ConsumerStatefulWidget {
  const _AddMilestoneButton({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_AddMilestoneButton> createState() => _AddMilestoneButtonState();
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
          ..showSnackBar(
            const SnackBar(content: Text('Failed to add milestone. Try again.')),
          );
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
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        onPressed: () => setState(() => _expanded = true),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add milestone'),
      ),
    );
  }
}
