import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/radii.dart';

/// Rectangular shimmer placeholder for loading states.
///
/// [width] defaults to [double.infinity]; the parent must provide bounded
/// horizontal constraints (e.g. inside a [ListView], [SliverList], or a
/// width-constrained [SizedBox]).
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = AppRadii.lg,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      excludeSemantics: true,
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceMuted,
        highlightColor: AppColors.surface,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
