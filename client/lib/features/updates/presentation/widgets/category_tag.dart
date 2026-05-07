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
    final base = switch (category) {
      UpdateCategory.progress => AppColors.categoryEmerald,
      UpdateCategory.milestone => AppColors.categoryBlue,
      UpdateCategory.deliverable => AppColors.categoryViolet,
      UpdateCategory.blocker => AppColors.categoryRed,
      UpdateCategory.inputNeeded => AppColors.categoryAmber,
    };
    final fg = switch (category) {
      UpdateCategory.progress => const Color(0xFF34D399),
      UpdateCategory.milestone => const Color(0xFF60A5FA),
      UpdateCategory.deliverable => const Color(0xFFA78BFA),
      UpdateCategory.blocker => const Color(0xFFF87171),
      UpdateCategory.inputNeeded => const Color(0xFFFBBF24),
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
