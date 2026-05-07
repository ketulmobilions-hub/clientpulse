import 'package:flutter/material.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/models/comment.dart';

class AgencyCommentTile extends StatelessWidget {
  const AgencyCommentTile({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isClient = comment.authorType == CommentAuthorType.client;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        comment.parentId != null ? AppSpacing.s32 : AppSpacing.s16,
        AppSpacing.s8,
        AppSpacing.s16,
        AppSpacing.s8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AuthorBadge(isClient: isClient),
              const SizedBox(width: AppSpacing.s8),
              Flexible(
                child: Text(
                  comment.authorName,
                  style: theme.textTheme.labelMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                _formatTimestamp(comment.createdAt),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(comment.body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.s8),
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
    final base =
        isClient ? AppColors.categoryEmerald : AppColors.categoryBlue;
    final fg = isClient ? const Color(0xFF34D399) : const Color(0xFF60A5FA);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 2),
      decoration: BoxDecoration(
        color: base.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        isClient ? 'Client' : 'Team',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.3,
        ),
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
