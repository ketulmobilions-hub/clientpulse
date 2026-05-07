import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/breakpoints.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'package:clientpulse/shared/providers/update_service_provider.dart';
import 'agency_comment_section.dart';
import 'attachment_list.dart';
import 'category_tag.dart';

const _kMonthAbbrev = [
  'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
  'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
];

String _formatRelativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 30) return '${diff.inDays}d ago';
  return '${(diff.inDays / 30).floor()}mo ago';
}

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
  bool _isExpanded = false;
  bool _hasEverExpanded = false;
  bool _deleting = false;

  // ValueNotifier instead of setState so hover changes don't rebuild the
  // card (and its expensive expanded children: MarkdownBody, AttachmentList,
  // AgencyCommentSection). Only the _RowActions ValueListenableBuilder rebuilds.
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

  void _onCommentAdded() {
    ref
        .read(updateNotifierProvider(widget.update.projectId).notifier)
        .incrementCommentCount(widget.update.id);
  }

  Future<void> _confirmDelete() async {
    if (_deleting) return;
    _deleting = true;
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
      _deleting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final attachCount = widget.update.attachmentCount ?? 0;
    final commentCount = widget.update.commentCount ?? 0;
    final relativeTime =
        _createdAt == null ? '' : _formatRelativeTime(_createdAt!);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => setState(() {
                _isExpanded = !_isExpanded;
                if (_isExpanded) _hasEverExpanded = true;
              }),
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16, vertical: AppSpacing.s12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DateBadge(date: _createdAt),
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
                          _MetaLine(
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
                        onDelete: _confirmDelete,
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more,
                          size: 18, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded && widget.update.body.isNotEmpty) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s16, AppSpacing.s12, AppSpacing.s16, 0),
                child: MarkdownBody(
                  data: widget.update.body,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: theme.textTheme.bodyMedium,
                  ),
                  shrinkWrap: true,
                ),
              ),
            ],
            // Lazy-mount: only inserted after first expand so collapsed cards
            // don't fire HTTP requests on initial list render. Once mounted,
            // Visibility keeps it alive to avoid reloading on toggle.
            if (attachCount > 0 && _hasEverExpanded)
              Visibility(
                visible: _isExpanded,
                maintainState: true,
                child: AttachmentList(updateId: widget.update.id),
              ),
            if (attachCount > 0 && _isExpanded) const Divider(height: 1),
            if (_isExpanded)
              AgencyCommentSection(
                updateId: widget.update.id,
                onCommentAdded: _onCommentAdded,
              ),
          ],
        ),
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    final dt = date;
    if (dt == null) {
      return const SizedBox(width: 44, height: 44);
    }
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _kMonthAbbrev[dt.month - 1],
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '${dt.day}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({
    required this.relativeTime,
    required this.attachCount,
    required this.commentCount,
  });

  final String relativeTime;
  final int attachCount;
  final int commentCount;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (relativeTime.isNotEmpty) relativeTime,
      if (attachCount > 0)
        '$attachCount ${attachCount == 1 ? 'attachment' : 'attachments'}',
      if (commentCount > 0)
        '$commentCount ${commentCount == 1 ? 'comment' : 'comments'}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' • '),
      style: const TextStyle(
          fontSize: 12, color: AppColors.textMuted, height: 1.4),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _RowActions extends StatelessWidget {
  const _RowActions({required this.visible, required this.onDelete});

  final bool visible;
  final VoidCallback onDelete;

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
