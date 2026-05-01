import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

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
    this.borderRadius = 12.0,
  });

  final double height;
  final double width;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Loading',
      excludeSemantics: true,
      child: Shimmer.fromColors(
        // ignore: deprecated_member_use
        baseColor: colorScheme.surfaceVariant,
        highlightColor: colorScheme.surface,
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
