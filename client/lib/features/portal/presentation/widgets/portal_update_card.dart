import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../shared/models/portal_comment.dart';
import '../../../../../shared/models/portal_update.dart';
import '../../../../../shared/models/update.dart';
import '../../../../../shared/providers/portal_service_provider.dart';
import '../../../../../shared/services/portal_service.dart';
import 'open_url_stub.dart'
    if (dart.library.html) 'open_url_web.dart';

const _kAuthorNameKey = 'portal_author_name';

class PortalUpdateCard extends ConsumerStatefulWidget {
  const PortalUpdateCard({
    super.key,
    required this.update,
    required this.token,
  });

  final PortalUpdate update;
  final String token;

  @override
  ConsumerState<PortalUpdateCard> createState() => _PortalUpdateCardState();
}

class _PortalUpdateCardState extends ConsumerState<PortalUpdateCard>
    with AutomaticKeepAliveClientMixin {
  bool _expanded = false;
  final List<PortalComment> _comments = [];
  final _nameController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _isSubmitting = false;
  String? _submitError;
  // Cancelled on dispose to abort any in-flight comment request.
  CancelToken _cancelToken = CancelToken();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadSavedAuthorName();
  }

  Future<void> _loadSavedAuthorName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kAuthorNameKey);
    if (saved != null && mounted) {
      _nameController.text = saved;
    }
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    _nameController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final name = _nameController.text.trim();
    final body = _bodyController.text.trim();

    if (name.isEmpty || body.isEmpty) {
      setState(() => _submitError = 'Name and comment are required.');
      return;
    }
    if (name.length > 100) {
      setState(() => _submitError = 'Name must be 100 characters or fewer.');
      return;
    }
    if (body.length > 5000) {
      setState(() => _submitError = 'Comment must be 5000 characters or fewer.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    // Fresh token per submission so dispose cancels only the active request.
    _cancelToken = CancelToken();

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    await prefs.setString(_kAuthorNameKey, name);
    if (!mounted) return;

    final portalService = await ref.read(portalServiceProvider.future);
    if (!mounted) return;

    // Body is sent as plain text; server sanitizes HTML before storing.
    try {
      final comment = await portalService.createPortalComment(
        token: widget.token,
        updateId: widget.update.id,
        authorName: name,
        body: body,
        cancelToken: _cancelToken,
      );
      if (mounted) {
        setState(() {
          _comments.insert(0, comment);
          _bodyController.clear();
          _isSubmitting = false;
        });
      }
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) return;
      if (mounted) {
        setState(() {
          _submitError = 'Something went wrong. Please try again.';
          _isSubmitting = false;
        });
      }
    } on PortalException catch (e) {
      if (mounted) {
        setState(() {
          _submitError = e.message;
          _isSubmitting = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _submitError = 'Something went wrong. Please try again.';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required by AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);
    final timestamp = _formatTimestamp(widget.update.createdAt);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: _expanded
                ? 'Collapse update: ${widget.update.title}'
                : 'Expand update: ${widget.update.title}',
            button: true,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _CategoryChip(category: widget.update.category),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(timestamp,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: theme.colorScheme.outline)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(widget.update.title,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                        color: theme.colorScheme.outline),
                  ],
                ),
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MarkdownBody(
                data: widget.update.body,
                styleSheet: MarkdownStyleSheet.fromTheme(theme),
                imageBuilder: (uri, title, alt) => Image.network(
                  uri.toString(),
                  fit: BoxFit.fitWidth,
                  width: double.infinity,
                ),
              ),
            ),
            if (widget.update.attachments.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text('Attachments',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: theme.colorScheme.outline)),
              ),
              ...widget.update.attachments.map(
                (a) => ListTile(
                  leading: const Icon(Icons.attach_file, size: 20),
                  title: Text(a.fileName,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(color: theme.colorScheme.primary)),
                  subtitle: a.fileSize != null
                      ? Text(_formatFileSize(a.fileSize!),
                          style: theme.textTheme.bodySmall)
                      : null,
                  onTap: () {
                    final url = a.fileUrl;
                    if (url.isNotEmpty) openUrl(url);
                  },
                ),
              ),
            ],
            _CommentSection(
              comments: _comments,
              nameController: _nameController,
              bodyController: _bodyController,
              isSubmitting: _isSubmitting,
              submitError: _submitError,
              onSubmit: _submitComment,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _CommentSection extends StatelessWidget {
  const _CommentSection({
    required this.comments,
    required this.nameController,
    required this.bodyController,
    required this.isSubmitting,
    required this.submitError,
    required this.onSubmit,
  });

  final List<PortalComment> comments;
  final TextEditingController nameController;
  final TextEditingController bodyController;
  final bool isSubmitting;
  final String? submitError;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            comments.isEmpty ? 'Comments' : 'Comments (${comments.length})',
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.outline),
          ),
        ),
        if (comments.isNotEmpty)
          ...comments.map((c) => _CommentTile(comment: c)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  hintText: 'Enter your name',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                maxLength: 100,
                enabled: !isSubmitting,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bodyController,
                decoration: const InputDecoration(
                  labelText: 'Comment',
                  hintText: 'Write your comment here',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
                maxLength: 5000,
                enabled: !isSubmitting,
              ),
              const SizedBox(height: 4),
              if (submitError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    submitError!,
                    style: TextStyle(
                        color: theme.colorScheme.error, fontSize: 12),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: Semantics(
                  label: isSubmitting ? 'Submitting comment' : 'Submit comment',
                  button: true,
                  child: FilledButton(
                    onPressed: isSubmitting ? null : onSubmit,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PortalComment comment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(comment.authorName,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(_formatTimestamp(comment.createdAt),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
          const SizedBox(height: 2),
          Text(comment.body, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final UpdateCategory category;

  @override
  Widget build(BuildContext context) {
    final color = _chipColor(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        category.displayLabel,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _chipColor(UpdateCategory c) => switch (c) {
        UpdateCategory.progress => const Color(0xFF2563EB),
        UpdateCategory.milestone => const Color(0xFF7C3AED),
        UpdateCategory.deliverable => const Color(0xFF0D9488),
        UpdateCategory.blocker => const Color(0xFFDC2626),
        UpdateCategory.inputNeeded => const Color(0xFFD97706),
      };
}

String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  // abs() handles future-dated records from clock skew — prevents "just now" for future timestamps.
  final diff = now.difference(dt).abs();
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

String _formatFileSize(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}
