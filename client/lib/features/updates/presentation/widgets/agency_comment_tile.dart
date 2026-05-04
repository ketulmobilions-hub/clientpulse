import 'package:flutter/material.dart';
import 'package:clientpulse/shared/models/comment.dart';

class AgencyCommentTile extends StatelessWidget {
  const AgencyCommentTile({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClient = comment.authorType == CommentAuthorType.client;

    return Padding(
      padding: EdgeInsets.fromLTRB(comment.parentId != null ? 32 : 16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AuthorBadge(isClient: isClient),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  comment.authorName,
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatTimestamp(comment.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(comment.body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 6),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _AuthorBadge extends StatelessWidget {
  const _AuthorBadge({required this.isClient});

  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final bg = isClient ? Colors.green.shade100 : Colors.blue.shade100;
    final fg = isClient ? Colors.green.shade800 : Colors.blue.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isClient ? 'Client' : 'Team',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

String _formatTimestamp(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
