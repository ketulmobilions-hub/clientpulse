import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'agency_comment_section.dart';
import 'attachment_list.dart';
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
  // True once the card has been expanded at least once. AttachmentList is only
  // mounted after first expand so it doesn't fire HTTP requests for collapsed
  // cards on initial list render.
  bool _hasEverExpanded = false;
  // Cached once on first build — avoids DateTime.now() drift across rebuilds.
  late final String _formattedDate = formatUpdateDate(widget.update.createdAt);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) _hasEverExpanded = true;
            }),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                    _formattedDate,
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
                        Icon(Icons.attach_file, size: 14,
                            color: theme.colorScheme.primary.withOpacity(0.8)),
                        const SizedBox(width: 4),
                        Text(
                          '$attachCount ${attachCount == 1 ? 'attachment' : 'attachments'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            decoration: TextDecoration.underline,
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
          // Lazy-mount: only inserted after first expand so collapsed cards
          // don't fire HTTP requests on initial list render. Once mounted,
          // Visibility keeps it alive to avoid reloading on toggle.
          if (attachCount > 0 && _hasEverExpanded)
            Visibility(
              visible: _isExpanded,
              maintainState: true,
              child: AttachmentList(updateId: widget.update.id),
            ),
          if (attachCount > 0 && _isExpanded)
            Divider(height: 1, thickness: 1, color: Colors.grey.shade200),
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
