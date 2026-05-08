import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/content_widths.dart';
import '../../../../core/theme/radii.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/models/project.dart';
import '../../../../shared/providers/auth_notifier.dart';
import '../../../../shared/providers/project_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/buttons/app_icon_button.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/responsive_content.dart';
import '../../../../shared/widgets/shimmer_card.dart';
import '../widgets/project_card.dart';

enum _StatusFilter { all, active, completed, archived }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  _StatusFilter _filter = _StatusFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Project> _applyFilters(List<Project> projects) {
    final query = _query.trim().toLowerCase();
    return projects.where((p) {
      switch (_filter) {
        case _StatusFilter.active:
          if (p.status != ProjectStatus.active) return false;
          break;
        case _StatusFilter.completed:
          if (p.status != ProjectStatus.completed) return false;
          break;
        case _StatusFilter.archived:
          if (p.status != ProjectStatus.archived) return false;
          break;
        case _StatusFilter.all:
          break;
      }
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.clientName.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final projectsAsync = ref.watch(projectNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppHeader(
        pageTitle: 'Projects',
        actions: [
          AppButton(
            label: 'New Project',
            icon: Icons.add,
            onPressed: () => context.goNamed(
              RouteNames.createProject,
              extra: true,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          AppIconButton(
            icon: Icons.logout_rounded,
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),
          const SizedBox(width: AppSpacing.s4),
        ],
      ),
      body: ResponsiveContent(
        maxWidth: AppContentWidth.standard,
        child: projectsAsync.when(
          loading: () => ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s20),
            itemCount: 4,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
            itemBuilder: (_, __) => const ShimmerCard(height: 96),
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
                onAction: () => context.goNamed(
                  RouteNames.createProject,
                  extra: true,
                ),
              );
            }

            final filtered = _applyFilters(projects);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.s16),
                TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search projects or clients',
                    prefixIcon: const Icon(Icons.search_rounded, size: 18),
                    suffixIcon: _query.isEmpty
                        ? null
                        : AppIconButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Clear search',
                            size: AppIconButtonSize.sm,
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.s12),
                Wrap(
                  spacing: AppSpacing.s8,
                  runSpacing: AppSpacing.s8,
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == _StatusFilter.all,
                      onTap: () => setState(() => _filter = _StatusFilter.all),
                    ),
                    _FilterChip(
                      label: 'Active',
                      selected: _filter == _StatusFilter.active,
                      onTap: () =>
                          setState(() => _filter = _StatusFilter.active),
                    ),
                    _FilterChip(
                      label: 'Completed',
                      selected: _filter == _StatusFilter.completed,
                      onTap: () =>
                          setState(() => _filter = _StatusFilter.completed),
                    ),
                    _FilterChip(
                      label: 'Archived',
                      selected: _filter == _StatusFilter.archived,
                      onTap: () =>
                          setState(() => _filter = _StatusFilter.archived),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    0,
                    AppSpacing.s16,
                    0,
                    AppSpacing.s8,
                  ),
                  child: Text(
                    '${filtered.length} ${filtered.length == 1 ? 'project' : 'projects'}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            'No projects match',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: 96),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.s12),
                          itemBuilder: (_, i) =>
                              ProjectCard(project: filtered[i]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12,
            vertical: AppSpacing.s8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
