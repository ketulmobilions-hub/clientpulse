import 'package:flutter/material.dart';

import '../../core/theme/breakpoints.dart';
import '../../core/theme/content_widths.dart';
import '../../core/theme/spacing.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppContentWidth.standard,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final basePad = viewportWidth < AppBreakpoints.mobile
            ? AppSpacing.s16
            : AppSpacing.s24;
        // Only switch to centered (viewport - maxWidth)/2 once there's at
        // least basePad on each side; below that threshold keep basePad so
        // content doesn't bunch in the awkward 1080–1130px viewport range.
        final sidePad = viewportWidth > maxWidth + 2 * basePad
            ? (viewportWidth - maxWidth) / 2
            : basePad;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePad),
          child: child,
        );
      },
    );
  }
}
