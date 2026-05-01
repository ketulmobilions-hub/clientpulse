import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/providers/comment_provider.dart';
import 'agency_comment_tile.dart';

class AgencyCommentSection extends ConsumerStatefulWidget {
  const AgencyCommentSection({
    super.key,
    required this.updateId,
    this.onCommentAdded,
  });

  final String updateId;
  final VoidCallback? onCommentAdded;

  @override
  ConsumerState<AgencyCommentSection> createState() => _AgencyCommentSectionState();
}

class _AgencyCommentSectionState extends ConsumerState<AgencyCommentSection> {
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    // Clear stale error whenever user edits the input (#9).
    _bodyController.addListener(_clearSubmitError);
  }

  void _clearSubmitError() {
    if (_submitError != null) setState(() => _submitError = null);
  }

  @override
  void dispose() {
    _bodyController.removeListener(_clearSubmitError);
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) return;
    if (body.length > 5000) {
      setState(() => _submitError = 'Comment must be 5000 characters or fewer.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await ref.read(commentNotifierProvider(widget.updateId).notifier).addComment(body);
      if (mounted) {
        _bodyController.clear();
        setState(() => _isSubmitting = false);
        widget.onCommentAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = 'Failed to post comment. Please try again.';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(commentNotifierProvider(widget.updateId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1),
        commentsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Text(
              'Failed to load comments. Tap to retry.',
              style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
            ),
          ),
          data: (comments) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  comments.isEmpty ? 'Comments' : 'Comments (${comments.length})',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: theme.colorScheme.outline),
                ),
              ),
              ...comments.map((c) => AgencyCommentTile(comment: c)),
              // Reply input only when comments loaded successfully (#8).
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // No ListenableBuilder wrapper — TextField state is not driven
                    // by the controller value, only by _isSubmitting (#13).
                    TextField(
                      controller: _bodyController,
                      decoration: const InputDecoration(
                        labelText: 'Reply',
                        hintText: 'Write a comment…',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      minLines: 2,
                      maxLines: 4,
                      maxLength: 5000,
                      enabled: !_isSubmitting,
                      textInputAction: TextInputAction.newline,
                    ),
                    if (_submitError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _submitError!,
                          style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ListenableBuilder(
                        listenable: _bodyController,
                        builder: (context, _) => FilledButton(
                          onPressed: (_isSubmitting || _bodyController.text.trim().isEmpty)
                              ? null
                              : _submitComment,
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Post'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
