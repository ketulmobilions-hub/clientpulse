import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/portal_overview.dart';
import '../../../../shared/providers/portal_provider.dart';
import '../../../../shared/services/portal_service.dart';
import '../widgets/portal_update_card.dart';

class PortalScreen extends ConsumerWidget {
  const PortalScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(portalOverviewProvider(token));

    return overviewAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) {
        final isTokenError = e is PortalException && e.isInvalidToken;
        return _PortalErrorScreen(
          message: isTokenError
              ? 'This link is invalid or has expired.'
              : 'Something went wrong. Please try again later.',
          onRetry: isTokenError
              ? null
              : () => ref.invalidate(portalOverviewProvider(token)),
        );
      },
      data: (overview) => _PortalContent(token: token, overview: overview),
    );
  }
}

class _PortalContent extends ConsumerWidget {
  const _PortalContent({required this.token, required this.overview});

  final String token;
  final PortalOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final updatesAsync = ref.watch(portalUpdatesNotifierProvider(token));
    final hasMilestones = overview.milestones.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            if (overview.workspace.logoUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  overview.workspace.logoUrl!,
                  height: 28,
                  width: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      overview.workspace.name.isNotEmpty
                          ? overview.workspace.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(overview.workspace.name),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // Project header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(overview.project.name,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('For ${overview.project.clientName}',
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(color: theme.colorScheme.outline)),
                      const SizedBox(width: 8),
                      _StatusBadge(status: overview.project.status),
                    ],
                  ),
                  if (overview.project.description != null) ...[
                    const SizedBox(height: 8),
                    Text(overview.project.description!,
                        style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ),

          // Milestone progress
          if (hasMilestones)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Milestones', style: theme.textTheme.titleSmall),
                        Text(
                          '${overview.progress.completed} of ${overview.progress.total} complete',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: theme.colorScheme.outline),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        // Clamp guards against backend rounding producing > 100%.
                        value: (overview.progress.percent / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: overview.milestones
                            .map((m) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _MilestoneChip(milestone: m),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Updates section header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
            sliver: SliverToBoxAdapter(
              child: Text('Updates',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),

          // Updates content — lazy via SliverList
          ...updatesAsync.when(
            loading: () => [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
            error: (e, _) => [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Text('Failed to load updates: $e',
                      style: TextStyle(color: theme.colorScheme.error)),
                ),
              ),
            ],
            data: (updatesState) {
              if (updatesState.updates.isEmpty) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No updates yet.',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.colorScheme.outline)),
                      ),
                    ),
                  ),
                ];
              }
              return [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.builder(
                    itemCount: updatesState.updates.length,
                    itemBuilder: (_, i) =>
                        PortalUpdateCard(update: updatesState.updates[i]),
                  ),
                ),
                if (updatesState.loadMoreError != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Failed to load more: ${updatesState.loadMoreError}',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  sliver: SliverToBoxAdapter(
                    child: updatesState.isLoadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : updatesState.hasMore
                            ? Center(
                                child: OutlinedButton(
                                  onPressed: () {
                                    ref
                                        .read(portalUpdatesNotifierProvider(token).notifier)
                                        .loadMore()
                                        .ignore();
                                  },
                                  child: const Text('Load more'),
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
                ),
              ];
            },
          ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PortalProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      PortalProjectStatus.active => Colors.green,
      PortalProjectStatus.completed => Colors.blue,
      PortalProjectStatus.archived => Colors.grey,
      PortalProjectStatus.unknown => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status.displayLabel,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.milestone});

  final PortalMilestone milestone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      avatar: Icon(
        milestone.completed ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 16,
        color: milestone.completed
            ? theme.colorScheme.primary
            : theme.colorScheme.outline,
      ),
      label: Text(milestone.title, style: theme.textTheme.bodySmall),
      backgroundColor: milestone.completed
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
    );
  }
}

class _PortalErrorScreen extends StatelessWidget {
  const _PortalErrorScreen({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link_off_rounded,
                  size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('Link Unavailable',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                FilledButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
