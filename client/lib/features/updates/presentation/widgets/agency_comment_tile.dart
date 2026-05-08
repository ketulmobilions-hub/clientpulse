import 'package:flutter/material.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/models/comment.dart';

class AgencyCommentTile extends StatefulWidget {
  const AgencyCommentTile({super.key, required this.comment});

  final Comment comment;

  @override
  State<AgencyCommentTile> createState() => _AgencyCommentTileState();
}

class _AgencyCommentTileState extends State<AgencyCommentTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = widget.comment;
    final isClient = c.authorType == CommentAuthorType.client;
    final accent =
        isClient ? AppColors.categoryEmeraldFg : AppColors.categoryBlueFg;
    final bg = isClient
        ? AppColors.categoryEmerald.withOpacity(0.06)
        : AppColors.surfaceMuted;

    final outlineColor =
        _hovered ? AppColors.borderHover : AppColors.borderSubtle;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: EdgeInsets.fromLTRB(
          c.parentId != null ? AppSpacing.s32 : 0,
          0,
          0,
          AppSpacing.s12,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: outlineColor),
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _Avatar(name: c.authorName, accent: accent),
                          const SizedBox(width: AppSpacing.s12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        c.authorName,
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.s8),
                                    _RoleTag(isClient: isClient),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTimestamp(c.createdAt),
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      Text(
                        c.body,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.accent});

  final String name;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withOpacity(0.16),
        border: Border.all(color: accent.withOpacity(0.3)),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: accent,
        ),
      ),
    );
  }
}

class _RoleTag extends StatelessWidget {
  const _RoleTag({required this.isClient});

  final bool isClient;

  @override
  Widget build(BuildContext context) {
    final (base, fg) = isClient
        ? (AppColors.categoryEmerald, AppColors.categoryEmeraldFg)
        : (AppColors.categoryBlue, AppColors.categoryBlueFg);
    final label = isClient ? 'Client' : 'Team';
    return Semantics(
      label: 'Role: $label',
      container: true,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s8, vertical: 2),
          decoration: BoxDecoration(
            color: base.withOpacity(0.18),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.characters.first.toUpperCase();
  return (parts.first.characters.first + parts.last.characters.first)
      .toUpperCase();
}

String _formatTimestamp(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
