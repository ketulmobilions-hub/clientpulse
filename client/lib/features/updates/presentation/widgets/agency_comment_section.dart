import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/core/theme/app_colors.dart';
import 'package:clientpulse/core/theme/radii.dart';
import 'package:clientpulse/core/theme/spacing.dart';
import 'package:clientpulse/shared/providers/comment_provider.dart';
import 'agency_comment_tile.dart';

class AgencyCommentSection extends ConsumerStatefulWidget {
  const AgencyCommentSection({
    super.key,
    required this.updateId,
    this.onCommentAdded,
  });

  final String updateId;
  final VoidCallback? onCommentAdded;

  @override
  ConsumerState<AgencyCommentSection> createState() =>
      _AgencyCommentSectionState();
}

class _AgencyCommentSectionState extends ConsumerState<AgencyCommentSection> {
  final _bodyController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSubmitting = false;
  bool _isFocused = false;
  bool _clearScheduled = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _bodyController.addListener(_clearSubmitError);
    _focusNode.addListener(() {
      if (mounted && _isFocused != _focusNode.hasFocus) {
        setState(() => _isFocused = _focusNode.hasFocus);
      }
    });
  }

  void _clearSubmitError() {
    if (_submitError == null || _clearScheduled) return;
    _clearScheduled = true;
    // Defer setState to next frame: controller listeners can fire during
    // build (autofill, programmatic text set) which would assert otherwise.
    // _clearScheduled dedupes — we only schedule one callback per error window.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clearScheduled = false;
      if (!mounted) return;
      if (_submitError != null) setState(() => _submitError = null);
    });
  }

  @override
  void dispose() {
    _bodyController.removeListener(_clearSubmitError);
    _bodyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty || _isSubmitting) return;
    if (body.length > 5000) {
      setState(
          () => _submitError = 'Comment must be 5000 characters or fewer.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await ref
          .read(commentNotifierProvider(widget.updateId).notifier)
          .addComment(body);
      if (mounted) {
        _bodyController.clear();
        setState(() => _isSubmitting = false);
        widget.onCommentAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitError = 'Failed to post comment. Please try again.';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(commentNotifierProvider(widget.updateId));
    // Render previous data while reloading (skipLoadingOnReload behavior)
    // so the list doesn't flash a spinner on every successful post.
    final cachedComments = commentsAsync.valueOrNull;

    Widget commentsBody;
    if (commentsAsync.isLoading && cachedComments == null) {
      commentsBody = const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (commentsAsync.hasError && cachedComments == null) {
      commentsBody = Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
        child: Row(
          children: [
            Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error),
            const SizedBox(width: AppSpacing.s8),
            Expanded(
              child: Text(
                'Failed to load comments.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.invalidate(commentNotifierProvider(widget.updateId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      final comments = cachedComments ?? const [];
      commentsBody = comments.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s12),
              child: Text(
                'No comments yet. Start the discussion below.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  comments.map((c) => AgencyCommentTile(comment: c)).toList(),
            );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        commentsBody,
        const SizedBox(height: AppSpacing.s16),
        _ReplyComposer(
          controller: _bodyController,
          focusNode: _focusNode,
          isFocused: _isFocused,
          isSubmitting: _isSubmitting,
          submitError: _submitError,
          onSubmit: _submitComment,
        ),
      ],
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  const _ReplyComposer({
    required this.controller,
    required this.focusNode,
    required this.isFocused,
    required this.isSubmitting,
    required this.submitError,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isFocused;
  final bool isSubmitting;
  final String? submitError;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final field = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): onSubmit,
        const SingleActivator(LogicalKeyboardKey.enter, control: true):
            onSubmit,
      },
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          hintText: 'Write a reply…',
          hintStyle:
              theme.textTheme.bodyMedium?.copyWith(color: AppColors.textFaint),
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          counterText: '',
        ),
        style: theme.textTheme.bodyMedium,
        minLines: 2,
        maxLines: 6,
        maxLength: 5000,
        enabled: !isSubmitting,
        textInputAction: TextInputAction.newline,
      ),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: isFocused ? AppColors.primary : AppColors.borderSubtle,
          width: isFocused ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field,
          if (submitError != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s4),
              child: Text(
                submitError!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: AppSpacing.s8),
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              final hintText = Text(
                'Markdown supported · ⌘/Ctrl + Enter to post',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textMuted),
                overflow: TextOverflow.ellipsis,
                maxLines: narrow ? 2 : 1,
              );
              final postButton = ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  final hasText = controller.text.trim().isNotEmpty;
                  return FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AppColors.primary.withOpacity(0.3),
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
                    ),
                    onPressed: (isSubmitting || !hasText) ? null : onSubmit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Post reply'),
                  );
                },
              );

              if (narrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    hintText,
                    const SizedBox(height: AppSpacing.s8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: postButton,
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(child: hintText),
                  postButton,
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
