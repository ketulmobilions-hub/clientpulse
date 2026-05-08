import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/route_names.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({
    super.key,
    this.pageTitle,
    this.actions,
    this.leading,
    this.onBrandTap,
  });

  final String? pageTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onBrandTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.appBarTheme.titleTextStyle ??
        theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leading: leading,
      title: Row(
        children: [
          Tooltip(
            message: 'Go to dashboard',
            child: Semantics(
              button: true,
              label: 'ClientPulse — go to dashboard',
              child: InkWell(
                onTap: onBrandTap ??
                    () => context.goNamed(RouteNames.dashboard),
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'ClientPulse',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: pageTitle == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        pageTitle!,
                        style: titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
            ),
          ),
        ],
      ),
      actions: actions,
    );
  }
}
