import 'package:flutter/material.dart';

import '../../core/theme/breakpoints.dart';
import '../../core/theme/content_widths.dart';
import '../../core/theme/spacing.dart';

class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppContentWidth.standard,
    this.verticalPadding = EdgeInsets.zero,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry verticalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        final basePad =
            viewportWidth < AppBreakpoints.mobile ? AppSpacing.s16 : AppSpacing.s24;
        final sidePad = viewportWidth > maxWidth
            ? (viewportWidth - maxWidth) / 2
            : basePad;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePad).add(verticalPadding),
          child: child,
        );
      },
    );
  }
}
