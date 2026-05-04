import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/models/milestone.dart';
import 'package:clientpulse/shared/providers/milestone_provider.dart';
import 'status_pill.dart';

class MilestoneTile extends ConsumerStatefulWidget {
  const MilestoneTile({
    super.key,
    required this.milestone,
    required this.projectId,
  });

  final Milestone milestone;
  final String projectId;

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
    if (!_focusNode.hasFocus && _editing) {
      _commitTitle();
    }
  }

  void _startEditing() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
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
    if (!mounted) return;
    if (picked == null) return;
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Checkbox(
            value: m.completed,
            onChanged: (_) => ref
                .read(milestoneNotifierProvider(widget.projectId).notifier)
                .toggleComplete(m.id)
                .catchError((e) {
              if (mounted) {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(SnackBar(content: Text('$e')));
              }
            }),
          ),
          Expanded(
            child: _editing
                ? TextField(
                    controller: _titleCtrl,
                    focusNode: _focusNode,
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
                          ? const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                  ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _pickDueDate,
            child: Chip(
              label: Text(
                m.dueDate ?? 'No date',
                style:
                    const TextStyle(fontSize: 11),
              ),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          StatusPill(status: m.status),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            visualDensity: VisualDensity.compact,
            tooltip: 'Delete',
            onPressed: _delete,
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
