import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_names.dart';
import '../../../../shared/models/project.dart';
import '../../../../shared/providers/auth_notifier.dart';
import '../../../../shared/providers/project_provider.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/error_state_widget.dart';
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
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(RouteNames.createProject),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Project'),
      ),
      body: projectsAsync.when(
        loading: () => ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          itemCount: 4,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
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
              onAction: () => context.goNamed(RouteNames.createProject),
            );
          }

          final filtered = _applyFilters(projects);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search projects or clients',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          ),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _FilterChip(
                      label: 'All',
                      selected: _filter == _StatusFilter.all,
                      onTap: () => setState(() => _filter = _StatusFilter.all),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Active',
                      selected: _filter == _StatusFilter.active,
                      onTap: () => setState(() => _filter = _StatusFilter.active),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Completed',
                      selected: _filter == _StatusFilter.completed,
                      onTap: () => setState(() => _filter = _StatusFilter.completed),
                    ),
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: 'Archived',
                      selected: _filter == _StatusFilter.archived,
                      onTap: () => setState(() => _filter = _StatusFilter.archived),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  '${filtered.length} ${filtered.length == 1 ? 'project' : 'projects'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No projects match',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => ProjectCard(project: filtered[i]),
                      ),
              ),
            ],
          );
        },
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w500,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : Colors.grey.shade300,
        ),
      ),
    );
  }
}
