import 'package:flutter/material.dart';
import '../../../../shared/models/project.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final ProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (status) {
      ProjectStatus.active => (Colors.green.shade100, Colors.green.shade800, 'Active'),
      ProjectStatus.completed => (Colors.blue.shade100, Colors.blue.shade800, 'Completed'),
      ProjectStatus.archived => (Colors.grey.shade200, Colors.grey.shade700, 'Archived'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
