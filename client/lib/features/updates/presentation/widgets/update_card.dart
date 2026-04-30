import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'category_tag.dart';

String formatUpdateDate(String isoString) {
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return isoString;
  final diff = DateTime.now().difference(dt.toLocal()).abs();
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, required this.update});

  final Update update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = update.attachmentCount ?? 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      elevation: 0,
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
                    update.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CategoryTag(category: update.category),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              formatUpdateDate(update.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            if (update.body.isNotEmpty) ...[
              const SizedBox(height: 8),
              MarkdownBody(
                data: update.body,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodySmall,
                ),
                shrinkWrap: true,
              ),
            ],
            if (count > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_file, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    '$count ${count == 1 ? 'attachment' : 'attachments'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

}
