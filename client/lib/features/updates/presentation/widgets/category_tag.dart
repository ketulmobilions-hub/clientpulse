import 'package:flutter/material.dart';
import 'package:clientpulse/shared/models/update.dart';

class CategoryTag extends StatelessWidget {
  const CategoryTag({super.key, required this.category});

  final UpdateCategory category;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (category) {
      UpdateCategory.progress => (Colors.green.shade100, Colors.green.shade800),
      UpdateCategory.milestone => (Colors.blue.shade100, Colors.blue.shade800),
      UpdateCategory.deliverable => (Colors.purple.shade100, Colors.purple.shade800),
      UpdateCategory.blocker => (Colors.red.shade100, Colors.red.shade800),
      UpdateCategory.inputNeeded => (Colors.orange.shade100, Colors.orange.shade800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category.displayLabel,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
