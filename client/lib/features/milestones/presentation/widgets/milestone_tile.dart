import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/models/milestone.dart';
import 'package:clientpulse/shared/providers/milestone_provider.dart';

const _kCardBg = Color(0xFF262626);
const _kCardBorder = Color(0xFF3F3F46);
const _kMuted = Color(0xFF71717A);
const _kGreen = Color(0xFF22C55E);
const _kAmber = Color(0xFFF59E0B);

class MilestoneTile extends ConsumerStatefulWidget {
  const MilestoneTile({
    super.key,
    required this.milestone,
    required this.projectId,
    required this.displayIndex,
    required this.isCurrentMilestone,
  });

  final Milestone milestone;
  final String projectId;
  final int displayIndex;
  final bool isCurrentMilestone;

  @override
  ConsumerState<MilestoneTile> createState() => _MilestoneTileState();
}

class _MilestoneTileState extends ConsumerState<MilestoneTile> {
  bool _editing = false;
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
    ref
        .read(milestoneNotifierProvider(widget.projectId).notifier)
        .updateDueDate(widget.milestone.id, dueDate: formatted)
        .catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$e')));
      }
    });
  }

  void _delete() {
    ref
        .read(milestoneNotifierProvider(widget.projectId).notifier)
        .delete(widget.milestone.id)
        .then((_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Milestone deleted')));
      }
    }).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('$e')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.milestone;
    final progressValue = m.completed ? 1.0 : 0.0;
    final progressColor = m.completed
        ? _kGreen
        : (widget.isCurrentMilestone ? _kAmber : _kCardBorder);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: _kCardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kCardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _MilestoneBadge(
                    displayIndex: widget.displayIndex,
                    completed: m.completed,
                    isCurrent: widget.isCurrentMilestone,
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
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            ),
                            onSubmitted: (_) => _commitTitle(),
                            textInputAction: TextInputAction.done,
                          )
                        : GestureDetector(
                            onTap: _startEditing,
                            child: Text(
                              m.title,
                              style: m.completed
                                  ? TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: _kMuted,
                                    )
                                  : null,
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  if (m.dueDate != null)
                    GestureDetector(
                      onTap: _pickDueDate,
                      child: Text(
                        _formatDate(m.dueDate!),
                        style: const TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _pickDueDate,
                      child: const Text(
                        'Add date',
                        style: TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    color: _kMuted,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Delete',
                    onPressed: _delete,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressValue,
                  minHeight: 4,
                  backgroundColor: _kCardBorder,
                  valueColor: AlwaysStoppedAnimation(progressColor),
                ),
              ),
            ],
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

class _MilestoneBadge extends StatelessWidget {
  const _MilestoneBadge({
    required this.displayIndex,
    required this.completed,
    required this.isCurrent,
  });

  final int displayIndex;
  final bool completed;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = completed
        ? _kGreen
        : (isCurrent ? _kAmber : _kCardBorder);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: completed
          ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
          : Text(
              '$displayIndex',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isCurrent ? Colors.white : _kMuted,
              ),
            ),
    );
  }
}
