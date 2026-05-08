import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/providers/milestone_provider.dart';
import 'package:clientpulse/shared/widgets/error_state_widget.dart';
import 'package:clientpulse/shared/widgets/shimmer_card.dart';
import 'milestone_tile.dart';

class MilestoneListWidget extends ConsumerWidget {
  const MilestoneListWidget({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(milestoneNotifierProvider(projectId));
    return milestonesAsync.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s8),
        itemBuilder: (_, __) => const ShimmerCard(height: 60),
      ),
      error: (e, _) => ErrorStateWidget(
        message: 'Failed to load milestones',
        onRetry: () =>
            ref.read(milestoneNotifierProvider(projectId).notifier).load(),
      ),
      data: (milestones) {
        final firstIncompleteIdx =
            milestones.indexWhere((m) => !m.completed);
        return ReorderableListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemCount: milestones.length,
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) => ref
              .read(milestoneNotifierProvider(projectId).notifier)
              .reorder(oldIndex, newIndex),
          footer: _InlineAddMilestoneRow(projectId: projectId),
          proxyDecorator: (child, index, animation) => Material(
            color: Colors.transparent,
            elevation: 6,
            shadowColor: const Color(0x66000000),
            borderRadius: BorderRadius.circular(10),
            child: child,
          ),
          itemBuilder: (_, i) => MilestoneTile(
            key: ValueKey(milestones[i].id),
            milestone: milestones[i],
            projectId: projectId,
            isCurrentMilestone: i == firstIncompleteIdx,
            dragIndex: i,
          ),
        );
      },
    );
  }
}

class _InlineAddMilestoneRow extends ConsumerStatefulWidget {
  const _InlineAddMilestoneRow({required this.projectId});

  final String projectId;

  @override
  ConsumerState<_InlineAddMilestoneRow> createState() =>
      _InlineAddMilestoneRowState();
}

class _InlineAddMilestoneRowState
    extends ConsumerState<_InlineAddMilestoneRow> {
  bool _expanded = false;
  bool _hovered = false;
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
            const SnackBar(
                content: Text('Failed to add milestone. Try again.')),
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
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.s12, AppSpacing.s8, AppSpacing.s8, AppSpacing.s8),
          child: Row(
            children: [
              const Icon(Icons.add_rounded, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Milestone title',
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Add'),
              ),
              const SizedBox(width: 4),
              TextButton(
                onPressed: () {
                  _ctrl.clear();
                  setState(() => _expanded = false);
                },
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 32),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadii.md),
            onTap: () => setState(() => _expanded = true),
            child: Container(
              decoration: BoxDecoration(
                color: _hovered ? AppColors.surfaceMuted : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadii.md),
                border: Border.all(
                  color:
                      _hovered ? AppColors.border : AppColors.borderSubtle,
                ),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12, vertical: AppSpacing.s12),
              child: Row(
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 18,
                    color:
                        _hovered ? AppColors.textFaint : AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Text(
                    'Add milestone',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _hovered
                          ? AppColors.textFaint
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
