import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/core/theme/content_widths.dart';
import 'package:clientpulse/shared/models/attachment.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/utils/file_utils.dart';
import 'package:clientpulse/shared/providers/storage_service_provider.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'package:clientpulse/shared/providers/update_service_provider.dart';
import 'package:clientpulse/shared/services/storage_service.dart';
import 'package:clientpulse/shared/services/update_service.dart';

// 10 MB — matches the Supabase Storage bucket hard limit so the client-side
// check catches oversized files before wasting bandwidth on a doomed upload.
const _kMaxFileSizeBytes = 10 * 1024 * 1024;

// Safe document and media types only. Executable/script extensions excluded to
// prevent using ClientPulse as a malware distribution vector.
const _kAllowedExtensions = [
  'pdf', 'png', 'jpg', 'jpeg', 'gif', 'webp',
  'mp4', 'mov', 'zip', 'csv', 'txt', 'doc', 'docx', 'xls', 'xlsx',
];

class _UpdateTemplate {
  const _UpdateTemplate({
    required this.label,
    required this.icon,
    required this.title,
    required this.body,
    required this.category,
  });

  final String label;
  final IconData icon;
  final String title;
  final String body;
  final UpdateCategory category;
}

const _kTemplates = <_UpdateTemplate>[
  _UpdateTemplate(
    label: 'Weekly progress update',
    icon: Icons.calendar_view_week_outlined,
    category: UpdateCategory.progress,
    title: 'Weekly progress — week of [date]',
    body: '''### What we shipped this week
-

### In progress
-

### Up next
-

### Notes
''',
  ),
  _UpdateTemplate(
    label: 'Deliverable ready',
    icon: Icons.inventory_2_outlined,
    category: UpdateCategory.deliverable,
    title: '[Deliverable name] is ready for review',
    body: '''### What's included
-

### How to review
1.

### Next steps
-
''',
  ),
  _UpdateTemplate(
    label: 'Blocker report',
    icon: Icons.warning_amber_outlined,
    category: UpdateCategory.blocker,
    title: 'Blocker: [short summary]',
    body: '''### What's blocked
-

### Why
-

### What we need from you
-

### Impact if unresolved
-
''',
  ),
  _UpdateTemplate(
    label: 'Client feedback request',
    icon: Icons.chat_bubble_outline,
    category: UpdateCategory.inputNeeded,
    title: 'Need your input on [topic]',
    body: '''### Context
-

### Options we're considering
1.
2.

### Question for you
-

_Please reply by [date]._
''',
  ),
];

({IconData icon, Color color}) _categoryStyle(UpdateCategory cat) =>
    switch (cat) {
      UpdateCategory.progress => (
          icon: Icons.construction_outlined,
          color: const Color(0xFFD97706), // amber-600
        ),
      UpdateCategory.milestone => (
          icon: Icons.flag_outlined,
          color: const Color(0xFF7C3AED), // violet-600
        ),
      UpdateCategory.deliverable => (
          icon: Icons.inventory_2_outlined,
          color: const Color(0xFF059669), // emerald-600
        ),
      UpdateCategory.blocker => (
          icon: Icons.warning_amber_outlined,
          color: const Color(0xFFDC2626), // red-600
        ),
      UpdateCategory.inputNeeded => (
          icon: Icons.chat_bubble_outline,
          color: const Color(0xFF2563EB), // blue-600
        ),
    };

class CreateUpdateScreen extends ConsumerStatefulWidget {
  const CreateUpdateScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<CreateUpdateScreen> createState() => _CreateUpdateScreenState();
}

class _CreateUpdateScreenState extends ConsumerState<CreateUpdateScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  late final TabController _tabController;

  UpdateCategory _selectedCategory = UpdateCategory.progress;
  List<PlatformFile> _selectedFiles = [];
  List<double> _fileProgress = []; // 0.0–1.0 per file, populated during upload
  bool _submitting = false;
  bool _isPicking = false; // prevents concurrent picker sessions (BUG-5)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Preview pane subscribes to _bodyController directly via ValueListenableBuilder,
    // so no tab-change listener is needed here. Adding one would rebuild the entire
    // form on every animation tick and clobber in-progress IME composition in the
    // body TextField.
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _applyTemplate(_UpdateTemplate tpl) {
    final hasContent =
        _titleController.text.trim().isNotEmpty || _bodyController.text.trim().isNotEmpty;
    void apply() {
      // Set value + collapse selection at end so the cursor lands at the tail
      // of the inserted text instead of position 0 (default for `.text =`).
      // Using TextEditingValue also avoids the controller's "reset undo stack"
      // behavior on direct text assignment.
      _titleController.value = TextEditingValue(
        text: tpl.title,
        selection: TextSelection.collapsed(offset: tpl.title.length),
      );
      _bodyController.value = TextEditingValue(
        text: tpl.body,
        selection: TextSelection.collapsed(offset: tpl.body.length),
      );
      setState(() => _selectedCategory = tpl.category);
    }

    if (!hasContent) {
      apply();
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace current draft?'),
        content: const Text('Applying a template will overwrite your current title and body.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              apply();
            },
            child: const Text('Replace'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    if (_isPicking || _selectedFiles.length >= 3) return;
    setState(() => _isPicking = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.custom,
        allowedExtensions: _kAllowedExtensions,
      );
      if (result == null || !mounted) return;

      final oversized = result.files.where((f) => (f.size) > _kMaxFileSizeBytes).toList();
      if (oversized.isNotEmpty) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(
            content: Text(
              '${oversized.map((f) => f.name).join(', ')} '
              'exceed the 10 MB limit and were skipped.',
            ),
          ));
      }

      final safe = result.files.where((f) => f.size <= _kMaxFileSizeBytes).toList();
      final remaining = 3 - _selectedFiles.length;
      final toAdd = safe.take(remaining).toList();
      if (toAdd.isNotEmpty) {
        setState(() {
          _selectedFiles = [..._selectedFiles, ...toAdd];
          _fileProgress = List.filled(_selectedFiles.length, 0.0);
        });
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _confirmAndSubmit() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Post update?'),
        content: const Text('Your client will receive an email notification.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _submit();
  }

  Future<void> _submit() async {
    // Jump (not animate) to Write tab so any validation error is visible
    // immediately. animateTo() takes ~200 ms; running validate() before the
    // indicator settles makes error messages flash under a moving tab.
    if (_tabController.index != 0) {
      _tabController.index = 0;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _fileProgress = List.filled(_selectedFiles.length, 0.0);
    });

    try {
      // Read services once before any async work — avoids provider re-resolution
      // after the update record has been created.
      final svc = await ref.read(updateServiceProvider.future);
      final storageSvc = await ref.read(storageServiceProvider.future);

      // Pre-flight: reject before creating the update record so no orphan is
      // left in the DB if bytes were lost (e.g. iOS memory pressure).
      if (_selectedFiles.isNotEmpty) {
        final unreadable = _selectedFiles
            .where((f) => f.bytes == null)
            .map((f) => f.name)
            .toList();
        if (unreadable.isNotEmpty) {
          throw StorageServiceException(
            'Could not read ${unreadable.join(', ')}. Please re-select the file(s) and try again.',
          );
        }
      }

      final update = await ref
          .read(updateNotifierProvider(widget.projectId).notifier)
          .createUpdate(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            category: _selectedCategory,
            status: 'published',
          );

      if (_selectedFiles.isNotEmpty) {
        final uploadedAttachments = <Attachment>[];
        try {
          for (var i = 0; i < _selectedFiles.length; i++) {
            final file = _selectedFiles[i];
            final bytes = file.bytes!; // non-null guaranteed by pre-flight above

            final mimeType = file.extension != null
                ? _mimeTypeForExtension(file.extension!)
                : 'application/octet-stream';

            final attachment = await storageSvc.uploadAttachment(
              updateId: update.id,
              fileName: file.name,
              bytes: bytes,
              mimeType: mimeType,
              onProgress: (p) {
                if (!mounted) return;
                // Bounds check: _fileProgress can be re-initialized by a
                // concurrent setState if the widget rebuilds mid-upload.
                if (i < _fileProgress.length) {
                  setState(() => _fileProgress[i] = p);
                }
              },
            );
            uploadedAttachments.add(attachment);
          }
        } catch (uploadErr) {
          // Best-effort rollback. Order matters: deleteAttachment removes both
          // the DB record AND the physical storage file. deleteUpdate must come
          // second — calling it first would cascade-delete attachment records,
          // leaving storage files with no DB entry to look up and orphaning them.
          for (final att in uploadedAttachments) {
            try {
              await storageSvc.deleteAttachment(att.id);
            } catch (e) {
              debugPrint('[CreateUpdateScreen] rollback deleteAttachment(${att.id}) failed: $e');
            }
          }
          try {
            await svc.deleteUpdate(update.id);
            ref.read(updateNotifierProvider(widget.projectId).notifier).remove(update.id);
          } catch (rollbackErr) {
            debugPrint('[CreateUpdateScreen] rollback deleteUpdate failed: $rollbackErr');
          }
          rethrow;
        }
      }

      // Refresh list so server-computed attachment_count is reflected.
      // Non-fatal: count will catch up on next list load if this fails.
      try {
        await ref.read(updateNotifierProvider(widget.projectId).notifier).load();
      } catch (_) {}

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Update posted')));
      setState(() => _submitting = false); // reset before pop in case of custom transitions
      Navigator.of(context).pop();
    } on StorageServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _submitting = false);
    } on UpdateServiceException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      setState(() => _submitting = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(SnackBar(content: Text('Error: $e')));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('New Update'),
        actions: [
          PopupMenuButton<_UpdateTemplate>(
            tooltip: 'Use template',
            enabled: !_submitting,
            icon: const Icon(Icons.auto_awesome_outlined),
            onSelected: _applyTemplate,
            itemBuilder: (ctx) => _kTemplates
                .map((tpl) => PopupMenuItem<_UpdateTemplate>(
                      value: tpl,
                      child: Row(
                        children: [
                          Icon(tpl.icon, size: 18, color: _categoryStyle(tpl.category).color),
                          const SizedBox(width: 12),
                          Text(tpl.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12, left: 4),
            child: FilledButton(
              onPressed: _submitting ? null : _confirmAndSubmit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(72, 36),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Post'),
            ),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppContentWidth.narrow),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              children: [
                // Title
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'What would you like to share?',
                  ),
                  maxLength: 200,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Title is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Content with Write/Preview tabs
                Text('Content', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                _WritePreviewTabs(
                  controller: _tabController,
                  writer: TextFormField(
                    controller: _bodyController,
                    decoration: const InputDecoration(
                      hintText: 'Markdown supported…',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    minLines: 8,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Body is required';
                      return null;
                    },
                  ),
                  preview: _PreviewPane(controller: _bodyController),
                ),
                const SizedBox(height: 20),

                // Category chips with icons + semantic colors
                Text('Category', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: UpdateCategory.values.map((cat) {
                    return _CategoryChip(
                      category: cat,
                      selected: _selectedCategory == cat,
                      onTap: () => setState(() => _selectedCategory = cat),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // Attachments — dropzone style
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Attachments', style: Theme.of(context).textTheme.labelLarge),
                    Text(
                      '${_selectedFiles.length}/3',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _AttachmentDropzone(
                  enabled: !_submitting && _selectedFiles.length < 3 && !_isPicking,
                  isFull: _selectedFiles.length >= 3,
                  onTap: _pickFiles,
                ),
                if (_selectedFiles.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ..._selectedFiles.asMap().entries.map((entry) {
                    final i = entry.key;
                    final file = entry.value;
                    final progress =
                        _submitting && i < _fileProgress.length ? _fileProgress[i] : null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.insert_drive_file_outlined, size: 20),
                          title: Text(file.name, overflow: TextOverflow.ellipsis),
                          subtitle: Text(formatFileSize(file.size)),
                          trailing: _submitting
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () => setState(() {
                                    _selectedFiles = List.from(_selectedFiles)..removeAt(i);
                                    _fileProgress = List.filled(_selectedFiles.length, 0.0);
                                  }),
                                ),
                        ),
                        if (progress != null)
                          LinearProgressIndicator(
                            value: progress > 0 ? progress : null,
                            minHeight: 2,
                          ),
                      ],
                    );
                  }),
                ],
                // Keyboard clearance
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WritePreviewTabs extends StatelessWidget {
  const _WritePreviewTabs({
    required this.controller,
    required this.writer,
    required this.preview,
  });

  final TabController controller;
  final Widget writer;
  final Widget preview;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // AnimatedBuilder rebuilds the TabBar (and the Semantics nodes inside
        // its `tabs` list) on every controller index change, so the selected
        // state announcement stays in sync with the visible indicator.
        AnimatedBuilder(
          animation: controller,
          builder: (ctx, _) => Container(
            decoration: BoxDecoration(
              color: scheme.surfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: controller,
              indicator: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: scheme.onSurface,
              unselectedLabelColor: scheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                // Custom indicator + transparent divider can suppress the
                // default selected announcement on some platforms; explicit
                // Semantics ensures it lands.
                Semantics(
                  selected: controller.index == 0,
                  child: const Tab(height: 32, text: 'Write'),
                ),
                Semantics(
                  selected: controller.index == 1,
                  child: const Tab(height: 32, text: 'Preview'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        // IndexedStack keeps the writer mounted while previewing so form
        // validators and controller state remain intact across tab switches.
        AnimatedBuilder(
          animation: controller,
          builder: (ctx, _) => IndexedStack(
            index: controller.index,
            sizing: StackFit.loose,
            children: [
              writer,
              preview,
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    // Subscribe to controller so the preview updates live as the user types
    // in Write, without requiring a parent rebuild on every keystroke.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (ctx, value, _) {
        final empty = value.text.trim().isEmpty;
        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: empty
              ? Text(
                  'Nothing to preview',
                  style: TextStyle(color: Colors.grey.shade500),
                )
              : MarkdownBody(data: value.text),
        );
      },
    );
  }
}

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final UpdateCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  @override
  Widget build(BuildContext context) {
    final style = _categoryStyle(widget.category);
    final selected = widget.selected;
    final borderColor = selected ? style.color : Colors.grey.shade300;
    final fg = selected ? style.color : Theme.of(context).colorScheme.onSurfaceVariant;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(20));

    // Material+InkWell gives keyboard focus, ripple, and hover state for free —
    // matching ChoiceChip's accessibility while keeping the custom look.
    return Semantics(
      button: true,
      selected: selected,
      label: widget.category.displayLabel,
      child: Material(
        color: selected ? style.color.withOpacity(0.12) : Colors.transparent,
        shape: shape.copyWith(
          side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          hoverColor: selected ? null : Colors.grey.shade100,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(style.icon, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  widget.category.displayLabel,
                  style: TextStyle(
                    color: fg,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentDropzone extends StatefulWidget {
  const _AttachmentDropzone({
    required this.enabled,
    required this.isFull,
    required this.onTap,
  });

  final bool enabled;
  final bool isFull;
  final VoidCallback onTap;

  @override
  State<_AttachmentDropzone> createState() => _AttachmentDropzoneState();
}

class _AttachmentDropzoneState extends State<_AttachmentDropzone> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = !widget.enabled;
    final fg = disabled ? Colors.grey.shade500 : Colors.grey.shade700;

    final label = widget.isFull
        ? 'Maximum 3 files reached'
        : 'Drop files here or browse';
    final sub = widget.isFull
        ? 'Remove a file to add another'
        : 'PDF, images, video, docs · up to 10 MB each';

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      hint: sub,
      child: MouseRegion(
        cursor: disabled ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
        child: Material(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: disabled ? null : widget.onTap,
            // Hover/focus colors driven by Material rather than manual MouseRegion
            // state — avoids stuck-hover when the widget shifts under a static cursor.
            hoverColor: scheme.primary.withOpacity(0.04),
            focusColor: scheme.primary.withOpacity(0.06),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isFull ? Icons.block : Icons.cloud_upload_outlined,
                    size: 32,
                    color: fg,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: fg,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: TextStyle(color: fg, fontSize: 12),
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

String _mimeTypeForExtension(String ext) => switch (ext.toLowerCase()) {
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'gif' => 'image/gif',
      'webp' => 'image/webp',
      'mp4' => 'video/mp4',
      'mov' => 'video/quicktime',
      'zip' => 'application/zip',
      'csv' => 'text/csv',
      'txt' => 'text/plain',
      'doc' => 'application/msword',
      'docx' =>
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls' => 'application/vnd.ms-excel',
      'xlsx' =>
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      _ => 'application/octet-stream',
    };
