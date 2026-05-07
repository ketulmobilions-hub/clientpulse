import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/models/portal_overview.dart';
import '../../../milestones/presentation/widgets/status_pill.dart';

final _dateFormat = DateFormat('MMM d, y');

String _formatDueDate(String isoDate) {
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return isoDate;
  return _dateFormat.format(dt.toLocal());
}

class PortalMilestoneSection extends StatefulWidget {
  const PortalMilestoneSection({
    super.key,
    required this.milestones,
    required this.progress,
  });

  final List<PortalMilestone> milestones;
  final PortalProgress progress;

  @override
  State<PortalMilestoneSection> createState() =>
      _PortalMilestoneSectionState();
}

class _PortalMilestoneSectionState extends State<PortalMilestoneSection> {
  static const _threshold = 5;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final milestones = widget.milestones;
    final progress = widget.progress;
    final progressPct = progress.percent.round();
    final shouldCollapse = milestones.length > _threshold;
    final displayed = shouldCollapse && !_expanded
        ? milestones.sublist(0, _threshold)
        : milestones;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s16,
        AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Milestones', style: theme.textTheme.titleMedium),
              Text(
                '${progress.completed} of ${progress.total} • $progressPct%',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.xs),
            child: LinearProgressIndicator(
              value: (progress.percent / 100).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          ...displayed.map((m) => _MilestoneRow(milestone: m)),
          if (shouldCollapse)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? 'Show less'
                    : 'Show all ${milestones.length} milestones',
              ),
            ),
        ],
      ),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  const _MilestoneRow({required this.milestone});

  final PortalMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = milestone.status;
    final formattedDate =
        milestone.dueDate != null ? _formatDueDate(milestone.dueDate!) : null;
    final semanticLabel =
        '${milestone.title}${formattedDate != null ? ', due $formattedDate' : ''}, ${status.displayLabel}';

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Row(
          children: [
            Expanded(
              child: Text(milestone.title, style: theme.textTheme.bodyMedium),
            ),
            if (formattedDate != null) ...[
              const SizedBox(width: AppSpacing.s8),
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            ],
            const SizedBox(width: AppSpacing.s8),
            StatusPill(status: status),
          ],
        ),
      ),
    );
  }
}
