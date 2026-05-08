import 'package:flutter/material.dart';

import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/models/update.dart';

class CategoryTag extends StatelessWidget {
  const CategoryTag({super.key, required this.category});

  final UpdateCategory category;

  @override
  Widget build(BuildContext context) {
    final (base, fg) = switch (category) {
      UpdateCategory.progress => (
          AppColors.categoryEmerald,
          AppColors.categoryEmeraldFg,
        ),
      UpdateCategory.milestone => (
          AppColors.categoryBlue,
          AppColors.categoryBlueFg,
        ),
      UpdateCategory.deliverable => (
          AppColors.categoryViolet,
          AppColors.categoryVioletFg,
        ),
      UpdateCategory.blocker => (
          AppColors.categoryRed,
          AppColors.categoryRedFg,
        ),
      UpdateCategory.inputNeeded => (
          AppColors.categoryAmber,
          AppColors.categoryAmberFg,
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
        category.displayLabel,
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
