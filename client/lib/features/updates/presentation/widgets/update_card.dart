import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'agency_comment_section.dart';
import 'attachment_list.dart';
import 'category_tag.dart';

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

const _kAvatarColors = [
  Color(0xFF7C3AED),
  Color(0xFF0891B2),
  Color(0xFF059669),
  Color(0xFFD97706),
  Color(0xFFDC2626),
  Color(0xFF2563EB),
  Color(0xFF0D9488),
  Color(0xFF9333EA),
];

class UpdateCard extends ConsumerStatefulWidget {
  const UpdateCard({super.key, required this.update});

  final Update update;

  @override
  ConsumerState<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends ConsumerState<UpdateCard> {
  bool _isExpanded = false;
  // Lazy-mount: only insert heavy widgets after first expand.
  bool _hasEverExpanded = false;
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AvatarBadge(authorId: widget.update.authorId),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.update.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _formattedDate,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (attachCount > 0) ...[
                    _CountChip(icon: Icons.attach_file, count: attachCount),
                    const SizedBox(width: 8),
                  ],
                  if (commentCount > 0) ...[
                    _CountChip(icon: Icons.chat_bubble_outline, count: commentCount),
                    const SizedBox(width: 8),
                  ],
                  CategoryTag(category: widget.update.category),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        size: 18, color: Color(0xFF71717A)),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded && widget.update.body.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MarkdownBody(
                data: widget.update.body,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodySmall,
                ),
                shrinkWrap: true,
              ),
            ),
          ],
          // Lazy-mount: only inserted after first expand so collapsed cards
          // don't fire HTTP requests on initial list render. Once mounted,
          // Visibility keeps it alive to avoid reloading on toggle.
          if (attachCount > 0 && _hasEverExpanded)
            Visibility(
              visible: _isExpanded,
              maintainState: true,
              child: AttachmentList(updateId: widget.update.id),
            ),
          if (attachCount > 0 && _isExpanded) const Divider(height: 1),
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

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.authorId});

  final String authorId;

  @override
  Widget build(BuildContext context) {
    final color = _kAvatarColors[authorId.hashCode.abs() % _kAvatarColors.length];
    final initials = authorId.length >= 2
        ? authorId.substring(0, 2).toUpperCase()
        : authorId.toUpperCase();
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF71717A)),
        const SizedBox(width: 3),
        Text(
          '$count',
          style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
        ),
      ],
    );
  }
}
