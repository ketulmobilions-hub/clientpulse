import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Milestones', style: theme.textTheme.titleSmall),
            Text(
              '${progress.completed} of ${progress.total} • $progressPct%',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            // Use raw float so bar fills accurately; label uses rounded int for readability.
            value: (progress.percent / 100).clamp(0.0, 1.0),
            minHeight: 8,
          ),
        ),
        const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(milestone.title, style: theme.textTheme.bodyMedium),
            ),
            if (formattedDate != null) ...[
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
            const SizedBox(width: 8),
            StatusPill(status: status),
          ],
        ),
      ),
    );
  }
}
