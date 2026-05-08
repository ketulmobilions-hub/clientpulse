import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/breakpoints.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'package:clientpulse/shared/providers/update_service_provider.dart';
import 'category_tag.dart';
import 'update_header.dart';

// Strips fenced/inline code, links, and common markdown punctuation so the
// 1-line preview renders as plain prose. Naive — not a sanitizer.
String _stripMarkdown(String body) {
  return body
      .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
      .replaceAll(RegExp(r'`([^`]*)`'), r'$1')
      .replaceAll(RegExp(r'!\[.*?\]\(.*?\)'), '')
      .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'$1')
      .replaceAll(RegExp(r'[#>*_~\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class UpdateCard extends ConsumerStatefulWidget {
  const UpdateCard({super.key, required this.update});

  final Update update;

  @override
  ConsumerState<UpdateCard> createState() => _UpdateCardState();
}

class _UpdateCardState extends ConsumerState<UpdateCard> {
  bool _deleting = false;

  // ValueNotifier instead of setState so hover changes don't rebuild the
  // card. Only the _RowActions ValueListenableBuilder rebuilds.
  final ValueNotifier<bool> _hovered = ValueNotifier(false);

  late DateTime? _createdAt;
  late String _preview;

  @override
  void initState() {
    super.initState();
    _recomputeDerived();
  }

  @override
  void didUpdateWidget(covariant UpdateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.update.createdAt != widget.update.createdAt ||
        oldWidget.update.body != widget.update.body) {
      _recomputeDerived();
    }
  }

  void _recomputeDerived() {
    _createdAt = DateTime.tryParse(widget.update.createdAt)?.toLocal();
    _preview = _stripMarkdown(widget.update.body);
  }

  @override
  void dispose() {
    _hovered.dispose();
    super.dispose();
  }

  void _openDetail() {
    context.pushNamed(
      RouteNames.updateDetailName,
      pathParameters: {
        'id': widget.update.projectId,
        'updateId': widget.update.id,
      },
    );
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
        await svc.deleteUpdate(widget.update.id);
        if (!mounted) return;
        ref
            .read(updateNotifierProvider(widget.update.projectId).notifier)
            .remove(widget.update.id);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(const SnackBar(content: Text('Update deleted')));
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachCount = widget.update.attachmentCount ?? 0;
    final commentCount = widget.update.commentCount ?? 0;
    final relativeTime =
        _createdAt == null ? '' : formatRelativeTime(_createdAt!);

    final width = MediaQuery.sizeOf(context).width;
    // Touch-leaning environments (mobile native + narrow web viewports) always
    // expose actions. Theme.of().platform is unreliable on Flutter Web (returns
    // macOS/Windows on mobile browsers) so we add a width fallback.
    final isMobileNative = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.android);
    final alwaysShowActions =
        isMobileNative || width < AppBreakpoints.mobile;

    return MouseRegion(
      onEnter: (_) => _hovered.value = true,
      onExit: (_) => _hovered.value = false,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Semantics(
          button: true,
          label: 'Open update: ${widget.update.title}',
          child: InkWell(
            onTap: _openDetail,
            borderRadius: BorderRadius.circular(AppRadii.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DateBadge(date: _createdAt),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.update.title,
                                style: theme.textTheme.titleMedium,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.s8),
                            CategoryTag(category: widget.update.category),
                          ],
                        ),
                        if (_preview.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.s4),
                          Text(
                            _preview,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.textFaint,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.s8),
                        MetaLine(
                          relativeTime: relativeTime,
                          attachCount: attachCount,
                          commentCount: commentCount,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  ValueListenableBuilder<bool>(
                    valueListenable: _hovered,
                    builder: (_, hovered, __) => _RowActions(
                      visible: alwaysShowActions || hovered,
                      onDelete: _deleting ? null : _confirmDelete,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.visible, required this.onDelete});

  final bool visible;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      excluding: !visible,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: visible ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !visible,
          child: IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: AppColors.textMuted,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            tooltip: 'Delete',
            onPressed: visible ? onDelete : null,
          ),
        ),
      ),
    );
  }
}
