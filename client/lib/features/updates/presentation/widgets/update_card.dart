import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/shared/models/update.dart';
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

const _kMuted = Color(0xFF71717A);

class UpdateCard extends StatelessWidget {
  const UpdateCard({super.key, required this.update});

  final Update update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachCount = update.attachmentCount ?? 0;
    final commentCount = update.commentCount ?? 0;
    final formattedDate = formatUpdateDate(update.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        onTap: () => context.goNamed(
          RouteNames.updateDetail,
          pathParameters: {
            'id': update.projectId,
            'updateId': update.id,
          },
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _AvatarBadge(authorId: update.authorId),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      update.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 12, color: _kMuted),
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
              CategoryTag(category: update.category),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 16, color: _kMuted),
            ],
          ),
        ),
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
        Icon(icon, size: 13, color: _kMuted),
        const SizedBox(width: 3),
        Text('$count', style: const TextStyle(fontSize: 12, color: _kMuted)),
      ],
    );
  }
}
