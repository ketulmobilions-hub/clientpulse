import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clientpulse/shared/models/update.dart';
import 'package:clientpulse/shared/providers/update_provider.dart';
import 'package:clientpulse/shared/providers/update_service_provider.dart';
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

class CreateUpdateScreen extends ConsumerStatefulWidget {
  const CreateUpdateScreen({super.key, required this.projectId});

  final String projectId;

  @override
  ConsumerState<CreateUpdateScreen> createState() => _CreateUpdateScreenState();
}

class _CreateUpdateScreenState extends ConsumerState<CreateUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  UpdateCategory _selectedCategory = UpdateCategory.progress;
  bool _previewMode = false;
  List<PlatformFile> _selectedFiles = [];
  bool _submitting = false;
  bool _isPicking = false; // prevents concurrent picker sessions (BUG-5)

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
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
              'exceed the 20 MB limit and were skipped.',
            ),
          ));
      }

      final safe = result.files.where((f) => f.size <= _kMaxFileSizeBytes).toList();
      final remaining = 3 - _selectedFiles.length;
      final toAdd = safe.take(remaining).toList();
      if (toAdd.isNotEmpty) {
        setState(() => _selectedFiles = [..._selectedFiles, ...toAdd]);
      }
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      // Read service once before any async work — avoids provider re-resolution
      // inside the upload loop after the update record has already been created.
      // Inside the try so a provider failure resets _submitting (1a).
      final svc = await ref.read(updateServiceProvider.future);
      // Step 1: Create the update record.
      final update = await ref.read(updateNotifierProvider(widget.projectId).notifier).createUpdate(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            category: _selectedCategory,
          );

      // Step 2: Upload attachments. If any step fails, roll back the created
      // update so no ghost record is left in the DB (BUG-2).
      if (_selectedFiles.isNotEmpty) {
        try {
          for (final file in _selectedFiles) {
            final bytes = file.bytes;
            if (bytes == null) continue;

            final mimeType = file.extension != null
                ? _mimeTypeForExtension(file.extension!)
                : 'application/octet-stream';

            final urls = await svc.getAttachmentSignedUrl(
              update.id,
              fileName: file.name,
              mimeType: mimeType,
            );

            await UpdateService.uploadToSignedUrl(
              urls['signedUrl']!,
              bytes, // bytes.length used for fileSize below — more reliable than file.size on web
              mimeType,
            );

            await svc.saveAttachment(
              update.id,
              fileUrl: urls['publicUrl']!,
              fileName: file.name,
              fileSize: bytes.length,
              mimeType: mimeType,
            );
          }
        } catch (uploadErr) {
          // Rollback: remove the orphaned update so the client portal stays clean.
          try {
            await svc.deleteUpdate(update.id);
            ref.read(updateNotifierProvider(widget.projectId).notifier).remove(update.id);
          } catch (rollbackErr) {
            // Best-effort rollback — log so ghost records are observable in production.
            debugPrint('[CreateUpdateScreen] rollback deleteUpdate failed: $rollbackErr');
          }
          rethrow;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Update posted')));
      // Do not setState here — Navigator.pop() disposes the widget immediately.
      Navigator.of(context).pop();
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
        title: const Text('New Update'),
        actions: [
          TextButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'What would you like to share?',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Title is required';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Body with preview toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Content',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _previewMode = !_previewMode),
                  child: Text(_previewMode ? 'Edit' : 'Preview'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (!_previewMode)
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  hintText: 'Markdown supported…',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 5,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Body is required';
                  return null;
                },
              )
            else
              Container(
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: _bodyController.text.trim().isEmpty
                    ? Text(
                        'Nothing to preview',
                        style: TextStyle(color: Colors.grey.shade500),
                      )
                    : MarkdownBody(data: _bodyController.text),
              ),
            const SizedBox(height: 20),

            // Category chips
            Text(
              'Category',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: UpdateCategory.values.map((cat) {
                return ChoiceChip(
                  label: Text(cat.displayLabel),
                  selected: _selectedCategory == cat,
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Attachments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Attachments',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                TextButton.icon(
                  onPressed: (_selectedFiles.length >= 3 || _isPicking)
                      ? null
                      : _pickFiles,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Add files'),
                ),
              ],
            ),
            if (_selectedFiles.isNotEmpty) ...[
              const SizedBox(height: 4),
              ..._selectedFiles.asMap().entries.map((entry) {
                final file = entry.value;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading:
                      const Icon(Icons.insert_drive_file_outlined, size: 20),
                  title: Text(
                    file.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_formatFileSize(file.size)),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(
                      () => _selectedFiles =
                          List.from(_selectedFiles)..removeAt(entry.key),
                    ),
                  ),
                );
              }),
            ],
            // Keyboard clearance
            const SizedBox(height: 80),
          ],
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
