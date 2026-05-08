import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum AppIconButtonSize { lg, md, sm }

enum AppIconButtonTone { neutral, danger, faint }

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = AppIconButtonSize.md,
    this.tone = AppIconButtonTone.neutral,
    this.semanticsLabel,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final AppIconButtonSize size;
  final AppIconButtonTone tone;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final dims = _dims(size);
    final color = switch (tone) {
      AppIconButtonTone.neutral => Theme.of(context).iconTheme.color,
      AppIconButtonTone.danger => AppColors.danger,
      AppIconButtonTone.faint => AppColors.textFaint,
    };

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, size: dims.iconSize, color: color),
      visualDensity: dims.density,
      padding: dims.padding,
      constraints: BoxConstraints.tightFor(
        width: dims.tap,
        height: dims.tap,
      ),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  _IconDims _dims(AppIconButtonSize s) => switch (s) {
        AppIconButtonSize.lg => const _IconDims(
            tap: 40,
            iconSize: 22,
            density: VisualDensity.standard,
            padding: EdgeInsets.all(8),
          ),
        AppIconButtonSize.md => const _IconDims(
            tap: 32,
            iconSize: 18,
            density: VisualDensity.compact,
            padding: EdgeInsets.all(6),
          ),
        AppIconButtonSize.sm => const _IconDims(
            tap: 28,
            iconSize: 16,
            density: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
      };
}

class _IconDims {
  const _IconDims({
    required this.tap,
    required this.iconSize,
    required this.density,
    required this.padding,
  });

  final double tap;
  final double iconSize;
  final VisualDensity density;
  final EdgeInsets padding;
}
