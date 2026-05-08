import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/radii.dart';

enum AppButtonVariant { primary, secondary, tertiary, danger }

enum AppButtonSize { lg, md, sm }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.md,
    this.icon,
    this.loading = false,
    this.fullWidth = false,
    this.tooltip,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final String? tooltip;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final dims = _dims(size);
    final effectiveOnPressed = loading ? null : onPressed;

    final spinner = SizedBox(
      width: dims.spinner,
      height: dims.spinner,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: _spinnerColor(context, variant),
      ),
    );

    final labelWidget = Text(label);

    Widget child;
    if (loading) {
      child = spinner;
    } else if (icon != null) {
      child = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dims.iconSize),
          const SizedBox(width: 8),
          labelWidget,
        ],
      );
    } else {
      child = labelWidget;
    }

    final style = ButtonStyle(
      minimumSize: MaterialStatePropertyAll(
        Size(fullWidth ? double.infinity : 0, dims.height),
      ),
      padding: MaterialStatePropertyAll(dims.padding),
      textStyle: MaterialStatePropertyAll(dims.textStyle),
      shape: MaterialStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.md)),
      ),
      backgroundColor: variant == AppButtonVariant.danger
          ? const MaterialStatePropertyAll(AppColors.danger)
          : null,
      foregroundColor: variant == AppButtonVariant.danger
          ? const MaterialStatePropertyAll(Colors.white)
          : null,
    );

    Widget button = switch (variant) {
      AppButtonVariant.primary || AppButtonVariant.danger => FilledButton(
          onPressed: effectiveOnPressed,
          autofocus: autofocus,
          style: style,
          child: child,
        ),
      AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          autofocus: autofocus,
          style: style,
          child: child,
        ),
      AppButtonVariant.tertiary => TextButton(
          onPressed: effectiveOnPressed,
          autofocus: autofocus,
          style: style,
          child: child,
        ),
    };

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }

  Color _spinnerColor(BuildContext context, AppButtonVariant v) {
    return switch (v) {
      AppButtonVariant.primary || AppButtonVariant.danger => Colors.white,
      AppButtonVariant.secondary ||
      AppButtonVariant.tertiary =>
        Theme.of(context).colorScheme.primary,
    };
  }

  _Dims _dims(AppButtonSize s) => switch (s) {
        AppButtonSize.lg => const _Dims(
            height: 44,
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.05),
            iconSize: 18,
            spinner: 20,
          ),
        AppButtonSize.md => const _Dims(
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            iconSize: 16,
            spinner: 16,
          ),
        AppButtonSize.sm => const _Dims(
            height: 28,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            iconSize: 14,
            spinner: 14,
          ),
      };
}

class _Dims {
  const _Dims({
    required this.height,
    required this.padding,
    required this.textStyle,
    required this.iconSize,
    required this.spinner,
  });

  final double height;
  final EdgeInsets padding;
  final TextStyle textStyle;
  final double iconSize;
  final double spinner;
}
