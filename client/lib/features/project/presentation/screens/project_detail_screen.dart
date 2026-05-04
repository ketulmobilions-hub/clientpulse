import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/core/constants.dart';
import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/features/dashboard/presentation/widgets/status_badge.dart';
import 'package:clientpulse/features/milestones/presentation/widgets/milestone_list_widget.dart';
import 'package:clientpulse/features/updates/presentation/widgets/update_card.dart';
import 'package:clientpulse/shared/models/project.dart';
import 'package:clientpulse/shared/providers/project_provider.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'package:clientpulse/shared/widgets/empty_state_widget.dart';
import 'package:clientpulse/shared/widgets/error_state_widget.dart';
import 'package:clientpulse/shared/widgets/shimmer_card.dart';

class ProjectDetailScreen extends ConsumerWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectListAsync = ref.watch(projectNotifierProvider);

    return projectListAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 3,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, __) => const ShimmerCard(height: 120),
        ),
      ),
      error: (_, __) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateWidget(
          message: 'Failed to load project',
          onRetry: () => ref.read(projectNotifierProvider.notifier).load(),
        ),
      ),
      data: (list) {
        final project =
            list.where((p) => p.id == projectId).firstOrNull;

        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Project not found')),
            body: EmptyStateWidget(
              icon: Icons.search_off_rounded,
              message: 'Project not found',
              actionLabel: 'Back to Dashboard',
              onAction: () => context.goNamed(RouteNames.dashboard),
            ),
          );
        }

        return _ProjectDetailContent(project: project, projectId: projectId);
      },
    );
  }
}

class _ProjectDetailContent extends StatefulWidget {
  const _ProjectDetailContent({
    required this.project,
    required this.projectId,
  });

  final Project project;
  final String projectId;

  @override
  State<_ProjectDetailContent> createState() => _ProjectDetailContentState();
}

class _ProjectDetailContentState extends State<_ProjectDetailContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit project',
            onPressed: () => context.pushNamed(
              RouteNames.editProject,
              pathParameters: {'id': project.id},
            ),
          ),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabs,
        builder: (_, __) => _tabs.index == 0
            ? FloatingActionButton(
                onPressed: () => context.pushNamed(
                  RouteNames.createUpdate,
                  pathParameters: {'id': project.id},
                ),
                tooltip: 'New update',
                child: const Icon(Icons.add),
              )
            : const SizedBox.shrink(),
      ),
      body: Column(
        children: [
          _ProjectHeader(project: project),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Updates'),
              Tab(text: 'Milestones'),
              Tab(text: 'Settings'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _UpdatesTab(projectId: widget.projectId),
                _MilestonesTab(projectId: widget.projectId),
                const _SettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectHeader extends StatelessWidget {
  const _ProjectHeader({required this.project});

  final Project project;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shareToken = project.shareToken;
    final shareUrl =
        shareToken != null ? '${AppConstants.appBaseUrl}/p/$shareToken' : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 5),
                    Text(
                      project.clientName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 10),
                    StatusBadge(status: project.status),
                  ],
                ),
                if (shareUrl != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.link_rounded, size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          shareUrl,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (shareUrl != null)
            Tooltip(
              message: 'Copy client link',
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: shareUrl));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                      ..clearSnackBars()
                      ..showSnackBar(
                        const SnackBar(content: Text('Link copied')),
                      );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_outlined, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 5),
                      Text(
                        'Copy link',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UpdatesTab extends ConsumerWidget {
  const _UpdatesTab({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updatesAsync = ref.watch(updateNotifierProvider(projectId));
    return updatesAsync.when(
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const ShimmerCard(height: 120),
      ),
      error: (e, _) => ErrorStateWidget(
        message: 'Failed to load updates',
        onRetry: () =>
            ref.read(updateNotifierProvider(projectId).notifier).load(),
      ),
      data: (updates) {
        if (updates.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.update_outlined,
            message: 'No updates yet',
            actionLabel: 'Post First Update',
            onAction: () => context.pushNamed(
              RouteNames.createUpdate,
              pathParameters: {'id': projectId},
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () =>
              ref.read(updateNotifierProvider(projectId).notifier).load(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: updates.length,
            itemBuilder: (_, i) => UpdateCard(
                  key: ValueKey(updates[i].id),
                  update: updates[i],
                ),
          ),
        );
      },
    );
  }
}

class _MilestonesTab extends StatelessWidget {
  const _MilestonesTab({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context) {
    return MilestoneListWidget(projectId: projectId);
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Settings coming soon'));
  }
}
