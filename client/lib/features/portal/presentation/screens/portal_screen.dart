import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/breakpoints.dart';
import '../../../../core/theme/content_widths.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/models/portal_overview.dart';
import '../../../../shared/providers/portal_provider.dart';
import '../../../../shared/services/portal_service.dart';
import '../../../../shared/widgets/shimmer_card.dart';
import '../widgets/portal_branding_header.dart';
import '../widgets/portal_milestone_section.dart';
import '../widgets/portal_update_card.dart';

double _portalSidePadding(double viewportWidth) {
  final basePad = viewportWidth < AppBreakpoints.mobile
      ? AppSpacing.s16
      : AppSpacing.s24;
  return viewportWidth > AppContentWidth.narrow
      ? (viewportWidth - AppContentWidth.narrow) / 2
      : basePad;
}

class PortalScreen extends ConsumerWidget {
  const PortalScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(portalOverviewProvider(token));

    return overviewAsync.when(
      loading: () => const Scaffold(body: _PortalLoadingScreen()),
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
      appBar: PortalBrandingHeader(workspace: overview.workspace),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final sidePad = _portalSidePadding(constraints.maxWidth);
          final bottomInset = MediaQuery.of(context).padding.bottom;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    sidePad, AppSpacing.s24, sidePad, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(overview.project.name,
                          style: theme.textTheme.headlineMedium),
                      const SizedBox(height: AppSpacing.s4),
                      Wrap(
                        spacing: AppSpacing.s8,
                        runSpacing: AppSpacing.s4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('For ${overview.project.clientName}',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textMuted)),
                          _StatusBadge(status: overview.project.status),
                        ],
                      ),
                      if (overview.project.description != null) ...[
                        const SizedBox(height: AppSpacing.s12),
                        Text(overview.project.description!,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textFaint)),
                      ],
                    ],
                  ),
                ),
              ),
              if (hasMilestones)
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                      sidePad, AppSpacing.s24, sidePad, 0),
                  sliver: SliverToBoxAdapter(
                    child: PortalMilestoneSection(
                      milestones: overview.milestones,
                      progress: overview.progress,
                    ),
                  ),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                    sidePad, AppSpacing.s24, sidePad, AppSpacing.s8),
                sliver: SliverToBoxAdapter(
                  child: Text('Updates', style: theme.textTheme.titleLarge),
                ),
              ),
              ...updatesAsync.when(
                loading: () => [
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: sidePad),
                    sliver: SliverList.separated(
                      itemCount: 3,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.s12),
                      itemBuilder: (_, __) => const ShimmerCard(height: 120),
                    ),
                  ),
                ],
                error: (_, __) => [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: sidePad, vertical: AppSpacing.s16),
                      child: Text('Failed to load updates. Please try again.',
                          style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ),
                ],
                data: (updatesState) {
                  if (updatesState.updates.isEmpty) {
                    return [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: AppSpacing.s32),
                          child: Center(
                            child: Text('No updates yet.',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textMuted)),
                          ),
                        ),
                      ),
                    ];
                  }
                  return [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: sidePad),
                      sliver: SliverList.builder(
                        itemCount: updatesState.updates.length,
                        itemBuilder: (_, i) => PortalUpdateCard(
                          key: ValueKey(updatesState.updates[i].id),
                          update: updatesState.updates[i],
                          token: token,
                        ),
                      ),
                    ),
                    if (updatesState.loadMoreError != null)
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                            sidePad, AppSpacing.s8, sidePad, 0),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            'Failed to load more updates. Please try again.',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                      sliver: SliverToBoxAdapter(
                        child: updatesState.isLoadingMore
                            ? const Center(child: CircularProgressIndicator())
                            : updatesState.hasMore
                                ? Center(
                                    child: OutlinedButton(
                                      onPressed: () {
                                        ref
                                            .read(portalUpdatesNotifierProvider(
                                                    token)
                                                .notifier)
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
              SliverPadding(
                  padding:
                      EdgeInsets.only(bottom: AppSpacing.s32 + bottomInset)),
            ],
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PortalProjectStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      PortalProjectStatus.active => (
          AppColors.categoryEmerald.withOpacity(0.18),
          const Color(0xFF34D399),
        ),
      PortalProjectStatus.completed => (
          AppColors.categoryBlue.withOpacity(0.18),
          const Color(0xFF60A5FA),
        ),
      PortalProjectStatus.archived ||
      PortalProjectStatus.unknown =>
        (AppColors.surfaceRaised, AppColors.textFaint),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadii.sm),
      ),
      child: Text(
        status.displayLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _PortalLoadingScreen extends StatelessWidget {
  const _PortalLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sidePad = _portalSidePadding(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding:
                  EdgeInsets.fromLTRB(sidePad, AppSpacing.s24, sidePad, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerCard(height: 32, width: constraints.maxWidth * 0.4),
                    const SizedBox(height: AppSpacing.s8),
                    ShimmerCard(
                        height: 18, width: constraints.maxWidth * 0.25),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding:
                  EdgeInsets.fromLTRB(sidePad, AppSpacing.s24, sidePad, 0),
              sliver: const SliverToBoxAdapter(child: ShimmerCard(height: 80)),
            ),
            SliverPadding(
              padding:
                  EdgeInsets.fromLTRB(sidePad, AppSpacing.s24, sidePad, 0),
              sliver: SliverList.separated(
                itemCount: 3,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.s12),
                itemBuilder: (_, __) => const ShimmerCard(height: 120),
              ),
            ),
          ],
        );
      },
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
          padding: const EdgeInsets.all(AppSpacing.s32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.link_off_rounded,
                  size: 56, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.s16),
              Text('Link Unavailable', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.s8),
              Text(message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textMuted)),
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.s20),
                FilledButton(
                    onPressed: onRetry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
