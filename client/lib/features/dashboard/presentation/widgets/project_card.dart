import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/models/project.dart';
import 'status_badge.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArchived = project.status == ProjectStatus.archived;

    final card = Card(
      child: InkWell(
        onTap: () => context.goNamed(
          RouteNames.projectDetail,
          pathParameters: {'id': project.id},
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        project.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          letterSpacing: -0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      _MetaRow(project: project),
                    ],
                  ),
                  Spacer(),
                  const SizedBox(width: AppSpacing.s12),
                  StatusBadge(status: project.status),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              if (project.latestUpdateTitle != null) ...[
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Last update: "${project.latestUpdateTitle}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (project.progressPct != null) ...[
                const SizedBox(height: AppSpacing.s12),
                _ProgressBar(
                    percent: project.progressPct!, archived: isArchived),
              ],
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Updated ${_formatDate(project.updatedAt)}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!isArchived) return card;

    // Archived: dim + grayscale to visually deprioritize. Wrapped in Semantics so screen readers
    // get the archived state announced even though the visual cue is purely chromatic.
    return Semantics(
      label: 'Archived project: ${project.name}',
      child: Opacity(
        opacity: 0.65,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(<double>[
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0.2126,
            0.7152,
            0.0722,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ]),
          child: card,
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    // Compare in local time so the absolute date display matches the user's wall clock
    // (otherwise a 23:30 UTC update viewed from PDT would render with the next day's date).
    final now = DateTime.now();
    final local = dt.isUtc ? dt.toLocal() : dt;
    final diff = now.difference(local);
    if (diff.isNegative || diff.inSeconds < 60) return 'just now';
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${local.day}/${local.month}/${local.year}';
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );

    final segments = <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline_rounded,
              size: 13, color: AppColors.textFaint),
          const SizedBox(width: AppSpacing.s4),
          Flexible(
            child: Text(
              project.clientName,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    ];

    final updates = project.updateCount;
    if (updates != null && updates > 0) {
      segments.add(Text(
        '$updates ${updates == 1 ? 'update' : 'updates'}',
        style: style,
      ));
    }

    final comments = project.commentCount;
    if (comments != null && comments > 0) {
      segments.add(Text(
        '$comments ${comments == 1 ? 'comment' : 'comments'}',
        style: style,
      ));
    }

    // Wrap (not Row) so segments break to a second line on narrow viewports
    // instead of overflowing with the yellow/black stripe.
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        for (var i = 0; i < segments.length; i++) ...[
          if (i > 0)
            Text('•', style: style?.copyWith(color: theme.colorScheme.outline)),
          segments[i],
        ],
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent, required this.archived});

  final int percent;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = archived ? AppColors.textMuted : AppColors.success;
    final clamped = percent.clamp(0, 100);

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xs),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
              valueColor: AlwaysStoppedAnimation<Color>(fill),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),
        Text(
          '$clamped%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
