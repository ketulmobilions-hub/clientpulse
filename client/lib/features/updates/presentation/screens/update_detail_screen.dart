import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/content_widths.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/features/updates/presentation/widgets/agency_comment_section.dart';
import 'package:clientpulse/features/updates/presentation/widgets/attachment_list.dart';
import 'package:clientpulse/features/updates/presentation/widgets/category_tag.dart';
import 'package:clientpulse/features/updates/presentation/widgets/update_header.dart';
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
    // Deep-link landing: if the cached list doesn't include this update yet,
    // kick off a reload before the first frame so the watch resolves to a
    // fresh AsyncLoading state instead of flashing "not found".
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
    setState(() => _deleting = true);
    try {
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
              style:
                  FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;

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

  AppBar _shellAppBar({String? title, bool showDelete = false}) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Back',
        onPressed: _backToProject,
      ),
      title: title == null
          ? null
          : Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        if (showDelete)
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete update',
            onPressed: _deleting ? null : _confirmDelete,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

        // List resolved but update not present. If we haven't tried a reload
        // yet (cache stale / deep-link race), the postFrame callback in
        // initState will trigger one; show shimmer until that resolves.
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
            appBar: _shellAppBar(title: 'Update not found'),
            body: EmptyStateWidget(
              icon: Icons.search_off_rounded,
              message: 'Update not found',
              actionLabel: 'Back to project',
              onAction: _backToProject,
            ),
          );
        }

        final createdAt = DateTime.tryParse(update.createdAt)?.toLocal();
        final relativeTime =
            createdAt == null ? '' : formatRelativeTime(createdAt);
        final attachCount = update.attachmentCount ?? 0;
        final commentCount = update.commentCount ?? 0;

        return Scaffold(
          appBar: _shellAppBar(title: update.title, showDelete: true),
          body: SafeArea(
            child: ResponsiveContent(
              maxWidth: AppContentWidth.standard,
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DateBadge(date: createdAt),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child:
                                    CategoryTag(category: update.category),
                              ),
                              const SizedBox(height: AppSpacing.s8),
                              MetaLine(
                                relativeTime: relativeTime,
                                attachCount: attachCount,
                                commentCount: commentCount,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (update.body.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s16),
                      const Divider(height: 1),
                      const SizedBox(height: AppSpacing.s12),
                      MarkdownBody(
                        data: update.body,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                    if (attachCount > 0) ...[
                      const SizedBox(height: AppSpacing.s16),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.s16,
                            AppSpacing.s12,
                            AppSpacing.s16,
                            AppSpacing.s4),
                        child: Text(
                          'Attachments',
                          style: theme.textTheme.labelMedium
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                      AttachmentList(updateId: update.id),
                    ],
                    AgencyCommentSection(
                      updateId: update.id,
                      onCommentAdded: _onCommentAdded,
                    ),
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
