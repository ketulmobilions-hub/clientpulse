import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/content_widths.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/features/updates/presentation/widgets/agency_comment_section.dart';
import 'package:clientpulse/features/updates/presentation/widgets/attachment_list.dart';
import 'package:clientpulse/features/updates/presentation/widgets/category_tag.dart';
import 'package:clientpulse/features/updates/presentation/widgets/update_header.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/providers/attachments_provider.dart';
import 'package:clientpulse/shared/providers/comment_provider.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'package:clientpulse/shared/providers/update_service_provider.dart';
import 'package:clientpulse/shared/widgets/empty_state_widget.dart';
import 'package:clientpulse/shared/widgets/error_state_widget.dart';
import 'package:clientpulse/shared/widgets/responsive_content.dart';
import 'package:clientpulse/shared/widgets/shimmer_card.dart';

class UpdateDetailScreen extends ConsumerStatefulWidget {
  const UpdateDetailScreen({
    super.key,
    required this.projectId,
    required this.updateId,
  });

  final String projectId;
  final String updateId;

  @override
  ConsumerState<UpdateDetailScreen> createState() => _UpdateDetailScreenState();
}

class _UpdateDetailScreenState extends ConsumerState<UpdateDetailScreen> {
  bool _deleting = false;

  // Tracks whether we proactively triggered a list reload because the update
  // was missing on first frame (deep-link or stale cache). Prevents repeated
  // reloads on every rebuild and lets us distinguish "still loading after
  // reload" from "list resolved without this update".
  bool _reloadTriggered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current =
          ref.read(updateNotifierProvider(widget.projectId)).valueOrNull;
      final found = current?.any((u) => u.id == widget.updateId) ?? false;
      if (!found) {
        _reloadTriggered = true;
        ref.read(updateNotifierProvider(widget.projectId).notifier).load();
      }
    });
  }

  void _backToProject() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(
        RouteNames.projectDetail,
        pathParameters: {'id': widget.projectId},
      );
    }
  }

  Future<void> _refresh() async {
    ref.invalidate(attachmentsProvider(widget.updateId));
    ref.invalidate(commentNotifierProvider(widget.updateId));
    await ref
        .read(updateNotifierProvider(widget.projectId).notifier)
        .load();
  }

  void _onCommentAdded() {
    ref
        .read(updateNotifierProvider(widget.projectId).notifier)
        .incrementCommentCount(widget.updateId);
  }

  Future<void> _confirmDelete() async {
    if (_deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Semantics(
          label: 'Delete update confirmation',
          child: const Text('Delete update?'),
        ),
        content: const Text(
            'This permanently removes the update and its attachments. Cannot be undone.'),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      final svc = await ref.read(updateServiceProvider.future);
      if (!mounted) return;
      try {
        await svc.deleteUpdate(widget.updateId);
        if (!mounted) return;
        ref
            .read(updateNotifierProvider(widget.projectId).notifier)
            .remove(widget.updateId);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Update deleted')));
        _backToProject();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  PreferredSizeWidget _shellAppBar({bool showActions = false}) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: _backToProject,
      ),
      actions: [
        if (showActions)
          Semantics(
            label: 'Update actions menu',
            button: true,
            child: PopupMenuButton<String>(
              tooltip: 'More actions',
              icon: const Icon(Icons.more_horiz),
              enabled: !_deleting,
              onSelected: (v) {
                if (v == 'delete') _confirmDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 18, color: AppColors.danger),
                      SizedBox(width: AppSpacing.s8),
                      Text('Delete update'),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final updatesAsync = ref.watch(updateNotifierProvider(widget.projectId));

    return updatesAsync.when(
      loading: () => Scaffold(
        appBar: _shellAppBar(),
        body: ResponsiveContent(
          maxWidth: AppContentWidth.standard,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
            itemBuilder: (_, __) => const ShimmerCard(height: 120),
          ),
        ),
      ),
      error: (_, __) => Scaffold(
        appBar: _shellAppBar(),
        body: ErrorStateWidget(
          message: 'Failed to load update',
          onRetry: _refresh,
        ),
      ),
      data: (updates) {
        final update =
            updates.where((u) => u.id == widget.updateId).firstOrNull;

        if (update == null) {
          if (!_reloadTriggered) {
            return Scaffold(
              appBar: _shellAppBar(),
              body: ResponsiveContent(
                maxWidth: AppContentWidth.standard,
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  itemCount: 3,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.s12),
                  itemBuilder: (_, __) => const ShimmerCard(height: 120),
                ),
              ),
            );
          }
          return Scaffold(
            appBar: _shellAppBar(),
            body: EmptyStateWidget(
              icon: Icons.search_off_rounded,
              message: 'Update not found',
              actionLabel: 'Back to project',
              onAction: _backToProject,
            ),
          );
        }

        // Counts derived from loaded async data when available, falling back
        // to the cached Update record while providers resolve. Keeps section
        // header in sync with actual rendered list (e.g. after a comment post).
        final attachmentsAsync = ref.watch(attachmentsProvider(update.id));
        final commentsAsync = ref.watch(commentNotifierProvider(update.id));
        final attachCount =
            attachmentsAsync.valueOrNull?.length ?? update.attachmentCount ?? 0;
        final commentCount =
            commentsAsync.valueOrNull?.length ?? update.commentCount ?? 0;

        return Scaffold(
          appBar: _shellAppBar(showActions: true),
          body: SafeArea(
            child: ResponsiveContent(
              maxWidth: AppContentWidth.standard,
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.s16),
                  children: [
                    _Hero(update: update),
                    if (update.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s32),
                      const _SectionHeader(label: 'Description'),
                      const SizedBox(height: AppSpacing.s8),
                      _BodyContent(body: update.body),
                    ],
                    const SizedBox(height: AppSpacing.s32),
                    _SectionHeader(
                        label: 'Attachments', count: attachCount),
                    const SizedBox(height: AppSpacing.s8),
                    AttachmentList(updateId: update.id),
                    const SizedBox(height: AppSpacing.s32),
                    _SectionHeader(
                        label: 'Discussion', count: commentCount),
                    const SizedBox(height: AppSpacing.s8),
                    AgencyCommentSection(
                      updateId: update.id,
                      onCommentAdded: _onCommentAdded,
                    ),
                    const SizedBox(height: AppSpacing.s32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.update});

  final Update update;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = DateTime.tryParse(update.createdAt)?.toLocal();
    final relativeTime =
        createdAt == null ? '' : formatRelativeTime(createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          update.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.2,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: AppSpacing.s12),
        Wrap(
          spacing: AppSpacing.s8,
          runSpacing: AppSpacing.s8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _MetaChip(
              icon: Icons.label_outline,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Category',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Flexible(child: CategoryTag(category: update.category)),
                ],
              ),
            ),
            if (relativeTime.isNotEmpty)
              _MetaChip(
                icon: Icons.schedule_outlined,
                child: Text(
                  relativeTime,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textFaint),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.child});

  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.s8),
          child,
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (count != null && count! > 0) ...[
          const SizedBox(width: AppSpacing.s8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textFaint,
              ),
            ),
          ),
        ],
        const Spacer(),
      ],
    );
  }
}

class _BodyContent extends StatelessWidget {
  const _BodyContent({required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MarkdownBody(
      data: body,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
        p: theme.textTheme.bodyLarge?.copyWith(
          height: 1.6,
          color: AppColors.textPrimary,
        ),
        h1: theme.textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
        h2: theme.textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
        h3: theme.textTheme.titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
      ),
    );
  }
}
