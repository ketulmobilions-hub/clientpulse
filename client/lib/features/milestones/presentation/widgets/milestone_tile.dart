import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/models/milestone.dart';
import 'package:clientpulse/shared/providers/milestone_provider.dart';

class MilestoneTile extends ConsumerStatefulWidget {
  const MilestoneTile({
    super.key,
    required this.milestone,
    required this.projectId,
    required this.isCurrentMilestone,
    required this.dragIndex,
  });

  final Milestone milestone;
  final String projectId;
  final bool isCurrentMilestone;
  final int dragIndex;

  @override
  ConsumerState<MilestoneTile> createState() => _MilestoneTileState();
}

class _MilestoneTileState extends ConsumerState<MilestoneTile> {
  bool _editing = false;
  bool _hovered = false;
  late TextEditingController _titleCtrl;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.milestone.title);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(MilestoneTile old) {
    super.didUpdateWidget(old);
    if (!_editing && old.milestone.title != widget.milestone.title) {
      _titleCtrl.text = widget.milestone.title;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _editing) _commitTitle();
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _commitTitle() {
    final title = _titleCtrl.text.trim();
    setState(() => _editing = false);
    if (title.isNotEmpty && title != widget.milestone.title) {
      ref
          .read(milestoneNotifierProvider(widget.projectId).notifier)
          .updateTitle(widget.milestone.id, title)
          .catchError((e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text('$e')));
          _titleCtrl.text = widget.milestone.title;
        }
      });
    } else if (title.isEmpty) {
      _titleCtrl.text = widget.milestone.title;
    }
  }

  Future<void> _pickDueDate() async {
    final current = widget.milestone.dueDate != null
        ? DateTime.tryParse(widget.milestone.dueDate!) ?? DateTime.now()
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    final formatted = picked.toIso8601String().substring(0, 10);
    try {
      await ref
          .read(milestoneNotifierProvider(widget.projectId).notifier)
          .updateDueDate(widget.milestone.id, dueDate: formatted);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleComplete() async {
    try {
      await ref
          .read(milestoneNotifierProvider(widget.projectId).notifier)
          .toggleComplete(widget.milestone.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _delete() async {
    try {
      await ref
          .read(milestoneNotifierProvider(widget.projectId).notifier)
          .delete(widget.milestone.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Milestone deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.milestone;
    final hasDate = m.dueDate != null;
    final platform = Theme.of(context).platform;
    final isTouchPlatform = platform == TargetPlatform.iOS ||
        platform == TargetPlatform.android;
    final showActions = isTouchPlatform || _hovered || _editing;
    final borderColor = _hovered
        ? AppColors.borderHover
        : (widget.isCurrentMilestone
            ? AppColors.categoryAmber.withOpacity(0.4)
            : AppColors.border);
    final bgColor = _hovered ? AppColors.surfaceHover : AppColors.surface;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: borderColor),
            boxShadow: _hovered
                ? const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.md),
              onTap: _editing ? null : _startEditing,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s12,
                  AppSpacing.s8,
                  AppSpacing.s8,
                  AppSpacing.s8,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _MilestoneCheckbox(
                      completed: m.completed,
                      isCurrent: widget.isCurrentMilestone,
                      onTap: _toggleComplete,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _editing
                          ? TextField(
                              controller: _titleCtrl,
                              focusNode: _focusNode,
                              autofocus: true,
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                              ),
                              onSubmitted: (_) => _commitTitle(),
                              textInputAction: TextInputAction.done,
                            )
                          : Text(
                              m.title,
                              style: m.completed
                                  ? const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.textMuted,
                                    )
                                  : const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    if (hasDate)
                      GestureDetector(
                        onTap: _pickDueDate,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          _formatDate(m.dueDate!),
                          style:
                              const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      )
                    else if (showActions)
                      GestureDetector(
                        onTap: _pickDueDate,
                        behavior: HitTestBehavior.opaque,
                        child: const Text(
                          'Add date',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ),
                    Semantics(
                      excludeSemantics: !showActions,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: showActions ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !showActions,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 16),
                            color: AppColors.textMuted,
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Delete',
                            onPressed: _delete,
                          ),
                        ),
                      ),
                    ),
                    ReorderableDragStartListener(
                      index: widget.dragIndex,
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Tooltip(
                          message: 'Drag to reorder',
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 4, vertical: 8),
                            child: Icon(Icons.drag_indicator,
                                size: 18, color: AppColors.textMuted),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dueDate) {
    final dt = DateTime.tryParse(dueDate);
    if (dt == null) return dueDate;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

class _MilestoneCheckbox extends StatefulWidget {
  const _MilestoneCheckbox({
    required this.completed,
    required this.isCurrent,
    required this.onTap,
  });

  final bool completed;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  State<_MilestoneCheckbox> createState() => _MilestoneCheckboxState();
}

class _MilestoneCheckboxState extends State<_MilestoneCheckbox> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final completed = widget.completed;
    final accent = widget.isCurrent ? AppColors.categoryAmber : AppColors.textMuted;

    final Color fill;
    final Color borderColor;
    if (completed) {
      fill = _hovered ? AppColors.successHover : AppColors.success;
      borderColor = fill;
    } else {
      fill = _hovered ? AppColors.surfaceHover : Colors.transparent;
      borderColor = _hovered ? accent : AppColors.border;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Tooltip(
          message: completed ? 'Mark incomplete' : 'Mark complete',
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(AppRadii.xs),
              border: Border.all(
                color: borderColor,
                width: _hovered || completed ? 2.0 : 1.8,
              ),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              child: completed
                  ? const Icon(
                      Icons.check_rounded,
                      key: ValueKey('done'),
                      size: 16,
                      color: Colors.white,
                    )
                  : (_hovered
                      ? Icon(
                          Icons.check_rounded,
                          key: const ValueKey('hover'),
                          size: 14,
                          color: accent,
                        )
                      : const SizedBox.shrink(key: ValueKey('empty'))),
            ),
          ),
        ),
      ),
    );
  }
}
