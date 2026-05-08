import 'package:flutter/material.dart';

import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';

const _kMonthAbbrev = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

String formatRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  final months = (diff.inDays / 30).floor();
  if (months < 12) return '${months}mo ago';
  return '${(months / 12).floor()}y ago';
}

class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final dt = date;
    if (dt == null) {
      return const SizedBox(width: 44, height: 44);
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _kMonthAbbrev[dt.month - 1],
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${dt.day}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class MetaLine extends StatelessWidget {
  const MetaLine({
    super.key,
    required this.relativeTime,
    required this.attachCount,
    required this.commentCount,
  });

  final String relativeTime;
  final int attachCount;
  final int commentCount;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (relativeTime.isNotEmpty) relativeTime,
      if (attachCount > 0)
        '$attachCount ${attachCount == 1 ? 'attachment' : 'attachments'}',
      if (commentCount > 0)
        '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' • '),
      style: const TextStyle(
          fontSize: 12, color: AppColors.textMuted, height: 1.4),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
