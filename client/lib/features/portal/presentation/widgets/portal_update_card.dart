import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../../shared/models/portal_update.dart';
import '../../../../../shared/models/update.dart';
import 'open_url_stub.dart'
    if (dart.library.html) 'open_url_web.dart';

class PortalUpdateCard extends StatefulWidget {
  const PortalUpdateCard({super.key, required this.update});

  final PortalUpdate update;

  @override
  State<PortalUpdateCard> createState() => _PortalUpdateCardState();
}

class _PortalUpdateCardState extends State<PortalUpdateCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp = _formatTimestamp(widget.update.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _CategoryChip(category: widget.update.category),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(timestamp,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: theme.colorScheme.outline)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(widget.update.title,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.outline),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MarkdownBody(
                data: widget.update.body,
                styleSheet: MarkdownStyleSheet.fromTheme(theme),
                imageBuilder: (uri, title, alt) => Image.network(
                  uri.toString(),
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
              ),
            ),
            if (widget.update.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Attachments',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
              ),
              ...widget.update.attachments.map(
                (a) => ListTile(
                  leading: const Icon(Icons.attach_file, size: 20),
                  title: Text(a.fileName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary)),
                  subtitle: a.fileSize != null
                      ? Text(_formatFileSize(a.fileSize!),
                          style: theme.textTheme.bodySmall)
                      : null,
                  onTap: () {
                    final url = a.fileUrl;
                    if (url.isNotEmpty) openUrl(url);
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final UpdateCategory category;

  @override
  Widget build(BuildContext context) {
    final color = _chipColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        category.displayLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _chipColor(UpdateCategory c) => switch (c) {
        UpdateCategory.progress => const Color(0xFF2563EB),
        UpdateCategory.milestone => const Color(0xFF7C3AED),
        UpdateCategory.deliverable => const Color(0xFF0D9488),
        UpdateCategory.blocker => const Color(0xFFDC2626),
        UpdateCategory.inputNeeded => const Color(0xFFD97706),
      };
}

String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  // Use abs() so future-dated records (clock skew) don't all show "just now".
  final diff = now.difference(dt).abs();
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}
