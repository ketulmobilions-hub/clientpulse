import 'package:flutter/material.dart';
import 'package:clientpulse/shared/models/milestone.dart';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status});

  final MilestoneStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      MilestoneStatus.upcoming => (Colors.blue.shade100, Colors.blue.shade800),
      MilestoneStatus.delayed => (Colors.red.shade100, Colors.red.shade800),
      MilestoneStatus.completed =>
        (Colors.green.shade100, Colors.green.shade800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.displayLabel,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
