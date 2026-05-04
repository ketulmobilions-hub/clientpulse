import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/models/project.dart';
import 'status_badge.dart';

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        // No borderRadius needed — Card's Clip.antiAlias handles shape clipping.
        onTap: () => context.goNamed(
          RouteNames.projectDetail,
          pathParameters: {'id': project.id},
        ),
        child: Stack(
          children: [
            // Left status accent bar — stretches to Stack height via Positioned.fill.
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                color: _accentColor(project.status, theme),
              ),
            ),
            // Main content — determines Stack height.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 48, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          project.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      StatusBadge(status: project.status),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        project.clientName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Updated ${_formatDate(project.updatedAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Chevron — centered vertically via Positioned + Center.
            Positioned(
              right: 14,
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(Icons.chevron_right_rounded,
                    color: Colors.grey.shade300, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _accentColor(ProjectStatus status, ThemeData theme) => switch (status) {
        ProjectStatus.active => theme.colorScheme.primary,
        ProjectStatus.completed => Colors.green.shade500,
        ProjectStatus.archived => Colors.grey.shade300,
      };

  String _formatDate(DateTime dt) {
    final now = DateTime.now().toUtc();
    final utc = dt.isUtc ? dt : dt.toUtc();
    final diff = now.difference(utc);
    if (diff.isNegative || diff.inSeconds < 60) return 'just now';
    if (diff.inDays == 0) {
      if (diff.inHours == 0) return '${diff.inMinutes}m ago';
      return '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${utc.day}/${utc.month}/${utc.year}';
  }
}
