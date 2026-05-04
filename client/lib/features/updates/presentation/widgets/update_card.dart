import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'agency_comment_section.dart';
import 'category_tag.dart';

/// Returns a human-readable relative time string for an ISO-8601 timestamp.
/// Falls back to a short date if parsing fails, never shows a raw DB string.
String formatUpdateDate(String isoString) {
  final dt = DateTime.tryParse(isoString)?.toLocal();
  if (dt == null) {
    return isoString.length > 10 ? isoString.substring(0, 10) : isoString;
  }
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

class UpdateCard extends ConsumerStatefulWidget {
  const UpdateCard({super.key, required this.update});

  final Update update;

  @override
  ConsumerState<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends ConsumerState<UpdateCard> {
  bool _isExpanded = false;

  void _onCommentAdded() {
    ref
        .read(updateNotifierProvider(widget.update.projectId).notifier)
        .incrementCommentCount(widget.update.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachCount = widget.update.attachmentCount ?? 0;
    final commentCount = widget.update.commentCount ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.update.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CategoryTag(category: widget.update.category),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(Icons.expand_more,
                            size: 18, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatUpdateDate(widget.update.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  // Body markdown shown only when expanded — prevents building
                  // heavy layout widgets for every card simultaneously (#10).
                  if (_isExpanded && widget.update.body.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: widget.update.body,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: theme.textTheme.bodySmall,
                      ),
                      shrinkWrap: true,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (attachCount > 0) ...[
                        Icon(Icons.attach_file, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          '$attachCount ${attachCount == 1 ? 'attachment' : 'attachments'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (commentCount > 0)
                        _CommentBadge(count: commentCount),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            AgencyCommentSection(
              updateId: widget.update.id,
              onCommentAdded: _onCommentAdded,
            ),
        ],
      ),
    );
  }
}

class _CommentBadge extends StatelessWidget {
  const _CommentBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chat_bubble_outline, size: 13, color: Colors.amber.shade700),
        const SizedBox(width: 3),
        Text(
          '$count ${count == 1 ? 'comment' : 'comments'}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.amber.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
