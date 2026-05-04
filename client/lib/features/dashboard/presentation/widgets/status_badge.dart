import 'package:flutter/material.dart';
import '../../../../shared/models/project.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (bg, fg, label) = switch (status) {
      ProjectStatus.active => isDark
          ? (const Color(0xFF14532D), const Color(0xFF4ADE80), 'Active')
          : (Colors.green.shade100, Colors.green.shade800, 'Active'),
      ProjectStatus.completed => isDark
          ? (const Color(0xFF1E3A5F), const Color(0xFF60A5FA), 'Completed')
          : (Colors.blue.shade100, Colors.blue.shade800, 'Completed'),
      ProjectStatus.archived => isDark
          ? (const Color(0xFF27272A), const Color(0xFF71717A), 'Archived')
          : (Colors.grey.shade200, Colors.grey.shade700, 'Archived'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isDark) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
