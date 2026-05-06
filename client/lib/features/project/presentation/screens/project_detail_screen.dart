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
import 'package:clientpulse/shared/models/update.dart';
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

    final nextMilestone = milestones.where((m) => !m.completed).firstOrNull;
    final pendingApprovals = updates
        .where((u) =>
            u.status == UpdateStatus.published &&
            u.category == UpdateCategory.inputNeeded)
        .length;
    final lastActivityAt = _latestActivity(updates, project.updatedAt);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProjectPageHeader(
              project: project,
              projectId: widget.projectId,
              updateCount: updates.length,
              pendingApprovals: pendingApprovals,
              lastActivityAt: lastActivityAt,
              nextMilestone: nextMilestone,
            ),
            if (milestones.isNotEmpty) ...[
              const SizedBox(height: 4),
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

  DateTime? _latestActivity(List<Update> updates, DateTime projectUpdatedAt) {
    DateTime latest = projectUpdatedAt;
    for (final u in updates) {
      final parsed = DateTime.tryParse(u.updatedAt);
      if (parsed != null && parsed.isAfter(latest)) latest = parsed;
    }
    return latest;
  }

  Widget _buildTabBar() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: cs.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: cs.inverseSurface,
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: cs.onInverseSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
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
    required this.pendingApprovals,
    required this.lastActivityAt,
    required this.nextMilestone,
  });

  final Project project;
  final String projectId;
  final int updateCount;
  final int pendingApprovals;
  final DateTime? lastActivityAt;
  final Milestone? nextMilestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shareToken = project.shareToken;
    final shareUrl =
        shareToken != null ? '${AppConstants.appBaseUrl}/p/$shareToken' : null;

    final cta = _resolveCta(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ClientAvatar(name: project.clientName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.clientName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: const Color(0xFFA1A1AA),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      project.name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: [
                        StatusBadge(status: project.status),
                        if (lastActivityAt != null)
                          _MetaChip(
                            icon: Icons.bolt_rounded,
                            label: 'Active ${_relTime(lastActivityAt!)}',
                          ),
                        if (pendingApprovals > 0)
                          _MetaChip(
                            icon: Icons.mark_email_unread_outlined,
                            label:
                                '$pendingApprovals pending ${pendingApprovals == 1 ? 'approval' : 'approvals'}',
                            tone: _ChipTone.warning,
                          ),
                        if (updateCount > 0)
                          _MetaChip(
                            icon: Icons.forum_outlined,
                            label:
                                '$updateCount ${updateCount == 1 ? 'update' : 'updates'}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                tooltip: 'Edit',
                onPressed: () => context.pushNamed(
                  RouteNames.editProject,
                  pathParameters: {'id': project.id},
                ),
                icon: const Icon(Icons.edit_outlined,
                    size: 18, color: Color(0xFFA1A1AA)),
              ),
              if (shareUrl != null) ...[
                const SizedBox(width: 4),
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
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
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
                onPressed: cta.onPressed,
                icon: Icon(cta.icon, size: 16),
                label: Text(cta.label),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
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

  _CtaSpec _resolveCta(BuildContext context) {
    void goCreate() => context.pushNamed(
          RouteNames.createUpdate,
          pathParameters: {'id': projectId},
        );

    if (pendingApprovals > 0) {
      return _CtaSpec(
        label: 'Reply to Client',
        icon: Icons.reply_rounded,
        onPressed: goCreate,
      );
    }
    final due = nextMilestone?.dueDate;
    if (due != null) {
      final dt = DateTime.tryParse(due);
      if (dt != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final dueDay = DateTime(dt.year, dt.month, dt.day);
        if (dueDay.isBefore(today)) {
          return _CtaSpec(
            label: 'Post Milestone Update',
            icon: Icons.flag_rounded,
            onPressed: goCreate,
          );
        }
      }
    }
    return _CtaSpec(
      label: 'New Update',
      icon: Icons.add,
      onPressed: goCreate,
    );
  }

  String _relTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 30) return '${diff.inDays}d ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo ago';
    return '${(months / 12).floor()}y ago';
  }
}

class _CtaSpec {
  const _CtaSpec(
      {required this.label, required this.icon, required this.onPressed});
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}

class _ClientAvatar extends StatelessWidget {
  const _ClientAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(name);
    final hue = name.hashCode % 360;
    final bg = HSLColor.fromAHSL(1, hue.toDouble(), 0.45, 0.32).toColor();
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kCardBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 15,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

enum _ChipTone { neutral, warning }

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.tone = _ChipTone.neutral,
  });

  final IconData icon;
  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      _ChipTone.warning => (const Color(0xFF3B2A11), const Color(0xFFFBBF24)),
      _ChipTone.neutral => (const Color(0xFF27272A), const Color(0xFFA1A1AA)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
