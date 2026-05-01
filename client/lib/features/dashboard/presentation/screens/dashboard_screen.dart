import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/providers/project_provider.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/shimmer_card.dart';
import '../widgets/project_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed(RouteNames.createProject),
        child: const Icon(Icons.add),
      ),
      body: projectsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, __) => const ShimmerCard(height: 88),
        ),
        error: (e, _) => ErrorStateWidget(
          message: 'Failed to load projects',
          onRetry: () => ref.read(projectNotifierProvider.notifier).load(),
        ),
        data: (projects) {
          if (projects.isEmpty) {
            return EmptyStateWidget(
              icon: Icons.folder_open_outlined,
              message: 'No projects yet',
              actionLabel: 'Create Project',
              onAction: () => context.pushNamed(RouteNames.createProject),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => ProjectCard(project: projects[i]),
          );
        },
      ),
    );
  }
}
