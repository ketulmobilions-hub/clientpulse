import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/models/project.dart';
import 'package:clientpulse/shared/providers/project_provider.dart';
import 'package:clientpulse/shared/widgets/buttons/app_button.dart';

/// Header overflow menu with Archive / Restore / Delete actions.
class ProjectActionsMenu extends ConsumerStatefulWidget {
  const ProjectActionsMenu({super.key, required this.project});

  final Project project;

  @override
  ConsumerState<ProjectActionsMenu> createState() => _ProjectActionsMenuState();
}

class _ProjectActionsMenuState extends ConsumerState<ProjectActionsMenu> {
  bool _busy = false;

  void _setBusy(bool v) {
    if (!mounted) return;
    setState(() => _busy = v);
  }

  @override
  Widget build(BuildContext context) {
    final isArchived = widget.project.status == ProjectStatus.archived;
    return PopupMenuButton<String>(
      tooltip: 'More actions',
      enabled: !_busy,
      icon: const Icon(Icons.more_horiz_rounded, color: AppColors.textMuted),
      onSelected: (value) async {
        // Synchronous re-entrancy guard. The build-time `enabled: !_busy`
        // disables the menu, but onSelected can still fire from a queued tap.
        if (_busy) return;
        switch (value) {
          case 'archive':
            await runProjectArchive(context, ref, widget.project,
                setBusy: _setBusy);
            break;
          case 'restore':
            await runProjectUnarchive(context, ref, widget.project,
                setBusy: _setBusy);
            break;
          case 'delete':
            await runProjectDelete(context, ref, widget.project,
                setBusy: _setBusy);
            break;
        }
      },
      itemBuilder: (ctx) => [
        if (!isArchived)
          const PopupMenuItem(
            value: 'archive',
            child: ListTile(
              leading: Icon(Icons.archive_outlined),
              title: Text('Archive'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        if (isArchived)
          const PopupMenuItem(
            value: 'restore',
            child: ListTile(
              leading: Icon(Icons.unarchive_outlined),
              title: Text('Restore'),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'delete',
          child: Semantics(
            label: 'Delete project, destructive action',
            button: true,
            child: const ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.redAccent),
              title: Text('Delete',
                  style: TextStyle(color: Colors.redAccent)),
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

/// Settings-tab "Danger zone" — two cards (Archive, Delete). Uses the same
/// dialogs as the header overflow so the action surface is consistent.
class ProjectDangerZone extends ConsumerStatefulWidget {
  const ProjectDangerZone({super.key, required this.project});

  final Project project;

  @override
  ConsumerState<ProjectDangerZone> createState() => _ProjectDangerZoneState();
}

class _ProjectDangerZoneState extends ConsumerState<ProjectDangerZone> {
  bool _busyArchive = false;
  bool _busyDelete = false;

  void _setArchiveBusy(bool v) {
    if (!mounted) return;
    setState(() => _busyArchive = v);
  }

  void _setDeleteBusy(bool v) {
    if (!mounted) return;
    setState(() => _busyDelete = v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isArchived = widget.project.status == ProjectStatus.archived;
    final anyBusy = _busyArchive || _busyDelete;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SettingsCard(
          title: isArchived ? 'Restore project' : 'Archive project',
          description: isArchived
              ? 'Move this project back to your active list.'
              : 'Hide this project from your active list. The client portal link stays live so clients can still view past updates.',
          child: AppButton(
            label: isArchived ? 'Restore' : 'Archive',
            variant: AppButtonVariant.secondary,
            icon: isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
            loading: _busyArchive,
            onPressed: anyBusy
                ? null
                : () async {
                    if (_busyArchive) return;
                    if (isArchived) {
                      await runProjectUnarchive(context, ref, widget.project,
                          setBusy: _setArchiveBusy);
                    } else {
                      await runProjectArchive(context, ref, widget.project,
                          setBusy: _setArchiveBusy);
                    }
                  },
          ),
        ),
        const SizedBox(height: AppSpacing.s16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: AppSpacing.s8),
                  Text('Delete project',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: Colors.redAccent)),
                ],
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Permanently deletes the project, all updates, milestones, and the client portal link. This cannot be undone from the app.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.s16),
              AppButton(
                label: 'Delete project',
                variant: AppButtonVariant.danger,
                icon: Icons.delete_outline,
                loading: _busyDelete,
                onPressed: anyBusy
                    ? null
                    : () async {
                        if (_busyDelete) return;
                        await runProjectDelete(
                            context, ref, widget.project,
                            setBusy: _setDeleteBusy);
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.s4),
          Text(description,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

// ----- Action runners (shared between menu + danger zone) ---------------------

String _truncateForSnack(String s, [int max = 60]) =>
    s.length > max ? '${s.substring(0, max)}…' : s;

Future<void> runProjectArchive(
  BuildContext context,
  WidgetRef ref,
  Project project, {
  required void Function(bool) setBusy,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Archive project?'),
      content: const Text(
          'Archived projects are hidden from your active list but remain accessible to clients via their portal link. You can restore later.'),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.tertiary,
          autofocus: true,
          onPressed: () => Navigator.of(ctx).pop(false),
        ),
        AppButton(
          label: 'Archive',
          variant: AppButtonVariant.secondary,
          onPressed: () => Navigator.of(ctx).pop(true),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  setBusy(true);
  try {
    await ref.read(projectNotifierProvider.notifier).archive(project.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Project archived')));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Archive failed: $e')));
  } finally {
    setBusy(false);
  }
}

Future<void> runProjectUnarchive(
  BuildContext context,
  WidgetRef ref,
  Project project, {
  required void Function(bool) setBusy,
}) async {
  setBusy(true);
  try {
    await ref.read(projectNotifierProvider.notifier).unarchive(project.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(content: Text('Project restored')));
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Restore failed: $e')));
  } finally {
    setBusy(false);
  }
}

Future<void> runProjectDelete(
  BuildContext context,
  WidgetRef ref,
  Project project, {
  required void Function(bool) setBusy,
}) async {
  // Type-to-confirm — defense-in-depth because soft-delete is unrecoverable from UI.
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => _DeleteConfirmDialog(projectName: project.name),
  );
  if (confirmed != true || !context.mounted) return;
  setBusy(true);
  bool popped = false;
  try {
    await ref.read(projectNotifierProvider.notifier).delete(project.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('Project "${_truncateForSnack(project.name)}" deleted')),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(RouteNames.dashboard);
    }
    popped = true;
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('Delete failed: $e')));
  } finally {
    // After successful delete the widget is unmounted; setBusy is a no-op
    // because callers guard with `mounted`. Skip the redundant call to make
    // intent clear.
    if (!popped) setBusy(false);
  }
}

class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({required this.projectName});
  final String projectName;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  final _controller = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      // Trim only the user input. The project name is compared verbatim so
      // a project literally named " Foo " requires the leading/trailing
      // spaces to match — preserves the strict-confirmation intent.
      final m = _controller.text.trim() == widget.projectName;
      if (m != _matches) setState(() => _matches = m);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete project?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              'This permanently deletes the project, all updates, milestones, and the client portal link. This cannot be undone from the app.'),
          const SizedBox(height: AppSpacing.s12),
          Text('Type "${widget.projectName}" to confirm:',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.s8),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(isDense: true),
          ),
        ],
      ),
      actions: [
        AppButton(
          label: 'Cancel',
          variant: AppButtonVariant.tertiary,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: 'Delete',
          variant: AppButtonVariant.danger,
          onPressed:
              _matches ? () => Navigator.of(context).pop(true) : null,
        ),
      ],
    );
  }
}
