import 'package:flutter/material.dart';

import '../../../../shared/models/portal_overview.dart';

class PortalBrandingHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const PortalBrandingHeader({super.key, required this.workspace});

  final PortalWorkspace workspace;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final displayName = workspace.name.isNotEmpty ? workspace.name : 'Portal';

    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          if (workspace.logoUrl != null) ...[
            Semantics(
              label: '$displayName logo',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  workspace.logoUrl!,
                  height: 28,
                  width: 28,
                  fit: BoxFit.cover,
                  cacheWidth: 56,
                  cacheHeight: 56,
                  loadingBuilder: (_, child, progress) =>
                      progress == null
                          ? child
                          : const SizedBox(width: 28, height: 28),
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(displayName, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
