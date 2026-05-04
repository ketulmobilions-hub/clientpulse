import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/core/constants.dart';
import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/features/dashboard/presentation/widgets/status_badge.dart';
import 'package:clientpulse/features/milestones/presentation/widgets/milestone_list_widget.dart';
import 'package:clientpulse/features/updates/presentation/widgets/update_card.dart';
import 'package:clientpulse/shared/models/milestone.dart';
import 'package:clientpulse/shared/models/project.dart';
import 'package:clientpulse/shared/providers/milestone_provider.dart';
import 'package:clientpulse/shared/providers/project_provider.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'package:clientpulse/shared/widgets/empty_state_widget.dart';
import 'package:clientpulse/shared/widgets/error_state_widget.dart';
import 'package:clientpulse/shared/widgets/shimmer_card.dart';

const _kCardBg = Color(0xFF262626);
const _kCardBorder = Color(0xFF3F3F46);
const _kMuted = Color(0xFF71717A);
const _kGreen = Color(0xFF22C55E);
const _kAmber = Color(0xFFF59E0B);

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
        final project = list.where((p) => p.id == projectId).firstOrNull;
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

class _ProjectDetailContent extends ConsumerStatefulWidget {
  const _ProjectDetailContent({required this.project, required this.projectId});

  final Project project;
  final String projectId;

  @override
  ConsumerState<_ProjectDetailContent> createState() =>
      _ProjectDetailContentState();
}

class _ProjectDetailContentState extends ConsumerState<_ProjectDetailContent>
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
    final milestones =
        ref.watch(milestoneNotifierProvider(widget.projectId)).valueOrNull ??
            [];
    final updates =
        ref.watch(updateNotifierProvider(widget.projectId)).valueOrNull ?? [];

    final totalMilestones = milestones.length;
    final completedMilestones = milestones.where((m) => m.completed).length;
    final progressPct =
        totalMilestones > 0 ? completedMilestones / totalMilestones : 0.0;
    final nextMilestone = milestones.where((m) => !m.completed).firstOrNull;
    final totalComments = updates.fold(0, (s, u) => s + (u.commentCount ?? 0));
    final totalAttachments =
        updates.fold(0, (s, u) => s + (u.attachmentCount ?? 0));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _ProjectPageHeader(
              project: project,
              projectId: widget.projectId,
              updateCount: updates.length,
            ),
            _StatsRow(
              progressPct: progressPct,
              completedMilestones: completedMilestones,
              totalMilestones: totalMilestones,
              updateCount: updates.length,
              totalComments: totalComments,
              totalAttachments: totalAttachments,
              nextMilestone: nextMilestone,
            ),
            if (milestones.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MilestoneStepper(milestones: milestones),
            ],
            _buildTabBar(),
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
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kCardBorder),
      ),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: _kCardBorder,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: _kMuted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [
          Tab(text: 'Updates'),
          Tab(text: 'Milestones'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }
}

class _ProjectPageHeader extends StatelessWidget {
  const _ProjectPageHeader({
    required this.project,
    required this.projectId,
    required this.updateCount,
  });

  final Project project;
  final String projectId;
  final int updateCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shareToken = project.shareToken;
    final shareUrl =
        shareToken != null ? '${AppConstants.appBaseUrl}/p/$shareToken' : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.name,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: project.status),
                    Text('·', style: const TextStyle(color: _kMuted)),
                    Text(
                      project.clientName,
                      style: theme.textTheme.bodySmall?.copyWith(color: _kMuted),
                    ),
                    if (updateCount > 0) ...[
                      const Text('·', style: TextStyle(color: _kMuted)),
                      Text(
                        '$updateCount ${updateCount == 1 ? 'update' : 'updates'}',
                        style: theme.textTheme.bodySmall?.copyWith(color: _kMuted),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
                InkWell(
                  onTap: () => context.pushNamed(
                    RouteNames.editProject,
                    pathParameters: {'id': project.id},
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.edit_outlined,
                        size: 18, color: Color(0xFFA1A1AA)),
                  ),
                ),
                if (shareUrl != null) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: shareUrl));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                          ..clearSnackBars()
                          ..showSnackBar(
                              const SnackBar(content: Text('Link copied')));
                      }
                    },
                    icon: const Icon(Icons.link_rounded, size: 15),
                    label: const Text('Client Portal Link'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 34),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                      side: const BorderSide(color: _kCardBorder),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => context.pushNamed(
                    RouteNames.createUpdate,
                    pathParameters: {'id': projectId},
                  ),
                  icon: const Icon(Icons.add, size: 15),
                  label: const Text('New Update'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 34),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    textStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.progressPct,
    required this.completedMilestones,
    required this.totalMilestones,
    required this.updateCount,
    required this.totalComments,
    required this.totalAttachments,
    required this.nextMilestone,
  });

  final double progressPct;
  final int completedMilestones;
  final int totalMilestones;
  final int updateCount;
  final int totalComments;
  final int totalAttachments;
  final Milestone? nextMilestone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _ProgressCard(
                pct: progressPct,
                completed: completedMilestones,
                total: totalMilestones,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _UpdatesStatCard(
                count: updateCount,
                comments: totalComments,
                attachments: totalAttachments,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NextMilestoneCard(milestone: nextMilestone),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder),
      ),
      child: child,
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard(
      {required this.pct, required this.completed, required this.total});

  final double pct;
  final int completed;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OVERALL PROGRESS',
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                color: _kMuted,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 6,
                      backgroundColor: _kCardBorder,
                      valueColor: const AlwaysStoppedAnimation(_kGreen),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(pct * 100).round()}%',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              if (total > 0) ...[
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completed / $total',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Text(
                      'milestones',
                      style: TextStyle(fontSize: 11, color: _kMuted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdatesStatCard extends StatelessWidget {
  const _UpdatesStatCard({
    required this.count,
    required this.comments,
    required this.attachments,
  });

  final int count;
  final int comments;
  final int attachments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL UPDATES',
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                color: _kMuted,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: theme.textTheme.displaySmall
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            '$comments comments · $attachments attachments',
            style: const TextStyle(fontSize: 11, color: _kMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _NextMilestoneCard extends StatelessWidget {
  const _NextMilestoneCard({required this.milestone});

  final Milestone? milestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StatCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'NEXT MILESTONE',
            style: TextStyle(
                fontSize: 9,
                letterSpacing: 0.8,
                color: _kMuted,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (milestone == null)
            Text(
              'All done!',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _kGreen,
              ),
            )
          else ...[
            Text(
              milestone!.title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (milestone!.dueDate != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatDueDate(milestone!.dueDate!),
                style: const TextStyle(fontSize: 11, color: _kMuted),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatDueDate(String dueDate) {
    final dt = DateTime.tryParse(dueDate);
    if (dt == null) return dueDate;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final dateStr = '${months[dt.month - 1]} ${dt.day}';
    final days = dt.difference(DateTime.now()).inDays;
    if (days < 0) return '$dateStr · ${-days}d overdue';
    if (days == 0) return '$dateStr · Today';
    return '$dateStr · ${days}d away';
  }
}

class _MilestoneStepper extends StatelessWidget {
  const _MilestoneStepper({required this.milestones});

  final List<Milestone> milestones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completedCount = milestones.where((m) => m.completed).length;
    final firstIncompleteIdx = milestones.indexWhere((m) => !m.completed);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: BoxDecoration(
        color: _kCardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Milestones', style: theme.textTheme.titleSmall),
              Text(
                '$completedCount of ${milestones.length} phases',
                style: const TextStyle(fontSize: 12, color: _kMuted),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < milestones.length; i++) ...[
                  _StepNode(
                    index: i,
                    milestone: milestones[i],
                    isCurrentMilestone: i == firstIncompleteIdx,
                  ),
                  if (i < milestones.length - 1)
                    _StepLine(
                      leftCompleted: milestones[i].completed,
                      isLeftCurrent: i == firstIncompleteIdx,
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.milestone,
    required this.isCurrentMilestone,
  });

  final int index;
  final Milestone milestone;
  final bool isCurrentMilestone;

  @override
  Widget build(BuildContext context) {
    final isCompleted = milestone.completed;
    final color =
        isCompleted ? _kGreen : (isCurrentMilestone ? _kAmber : _kCardBorder);

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: isCompleted
          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
          : Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isCurrentMilestone ? Colors.white : _kMuted,
              ),
            ),
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.leftCompleted, required this.isLeftCurrent});

  final bool leftCompleted;
  final bool isLeftCurrent;

  @override
  Widget build(BuildContext context) {
    final color =
        leftCompleted ? _kGreen : (isLeftCurrent ? _kAmber : _kCardBorder);
    return Container(width: 56, height: 2, color: color);
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
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.settings_outlined, size: 48, color: _kMuted),
            const SizedBox(height: 12),
            Text(
              'Project settings',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage team, permissions, and notifications',
              style: TextStyle(fontSize: 13, color: _kMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
