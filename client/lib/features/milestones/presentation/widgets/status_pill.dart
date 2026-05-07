import 'package:flutter/material.dart';

import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/models/milestone.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final MilestoneStatus status;

  @override
  Widget build(BuildContext context) {
    final (base, fg) = switch (status) {
      MilestoneStatus.upcoming => (
          AppColors.categoryBlue,
          const Color(0xFF60A5FA),
        ),
      MilestoneStatus.delayed => (
          AppColors.categoryRed,
          const Color(0xFFF87171),
        ),
      MilestoneStatus.completed => (
          AppColors.categoryEmerald,
          const Color(0xFF34D399),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8, vertical: 3),
      decoration: BoxDecoration(
        color: base.withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        status.displayLabel,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
