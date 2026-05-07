import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clientpulse/core/theme/content_widths.dart';
import 'package:clientpulse/shared/models/workspace.dart';
import 'package:clientpulse/shared/providers/workspace_provider.dart';
import 'package:clientpulse/shared/services/workspace_service.dart';

const _kMaxLogoBytes = 2 * 1024 * 1024; // 2 MB

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _nameInitialized = false;
  String? _pendingLogoUrl;
  bool _isUploading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Pre-fill from any already-loaded workspace (e.g. revisiting this screen).
      final existing = ref.read(workspaceNotifierProvider).valueOrNull;
      if (existing != null && !_nameInitialized) {
        _nameInitialized = true;
        _nameCtrl.text = existing.name;
      }
      // Always reload for fresh data — stale cache risk if workspace was
      // changed from another tab or by another admin.
      ref.read(workspaceNotifierProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    // Orphan cleanup: if the user navigated away without saving, discard the
    // pending upload. Read notifier before super.dispose() invalidates ref;
    // keepAlive notifier survives widget disposal so the async call completes.
    if (_pendingLogoUrl != null) {
      final notifier = ref.read(workspaceNotifierProvider.notifier);
      notifier.cleanupLogo(_pendingLogoUrl!).ignore();
    }
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    // Enforce client-side size limit before loading the full payload into memory.
    if ((file.size) > _kMaxLogoBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo must be smaller than 2 MB'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);
    try {
      final url = await ref
          .read(workspaceNotifierProvider.notifier)
          .uploadLogo(file.name, file.bytes!);
      if (mounted) setState(() => _pendingLogoUrl = url);
    } on WorkspaceServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logo upload failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(workspaceNotifierProvider.notifier).patchWorkspace(
            name: _nameCtrl.text.trim(),
            logoUrl: _pendingLogoUrl,
          );
      if (mounted) {
        setState(() => _pendingLogoUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workspace saved successfully'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on WorkspaceServiceException catch (e) {
      // Save failed — discard the pending upload to avoid orphaning it in storage.
      _discardPendingLogo();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _discardPendingLogo() {
    if (_pendingLogoUrl == null) return;
    final url = _pendingLogoUrl!;
    if (mounted) setState(() => _pendingLogoUrl = null);
    ref.read(workspaceNotifierProvider.notifier).cleanupLogo(url).ignore();
  }

  @override
  Widget build(BuildContext context) {
    final workspaceAsync = ref.watch(workspaceNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workspace Settings')),
      body: workspaceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Failed to load workspace: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.read(workspaceNotifierProvider.notifier).load(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (workspace) {
          if (workspace == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _SettingsBody(
            workspace: workspace,
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            pendingLogoUrl: _pendingLogoUrl,
            isUploading: _isUploading,
            isSaving: _isSaving,
            onUploadLogo: _pickAndUploadLogo,
            onSave: _save,
          );
        },
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.workspace,
    required this.formKey,
    required this.nameCtrl,
    required this.pendingLogoUrl,
    required this.isUploading,
    required this.isSaving,
    required this.onUploadLogo,
    required this.onSave,
  });

  final Workspace workspace;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final String? pendingLogoUrl;
  final bool isUploading;
  final bool isSaving;
  final VoidCallback onUploadLogo;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logoUrl = pendingLogoUrl ?? workspace.logoUrl;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppContentWidth.form),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SectionCard(
                  title: 'Workspace Logo',
                  child: Row(
                    children: [
                      _LogoPreview(logoUrl: logoUrl, name: workspace.name),
                      const SizedBox(width: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isUploading)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            OutlinedButton.icon(
                              onPressed: onUploadLogo,
                              icon: const Icon(Icons.upload_outlined, size: 18),
                              label: const Text('Change Logo'),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'PNG, JPG, GIF or WebP · max 2 MB',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Workspace Name',
                  child: TextFormField(
                    key: const Key('workspace_name_field'),
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Name'),
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => onSave(),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Workspace name is required';
                      if (val.length < 2) return 'Must be at least 2 characters';
                      if (val.length > 100) return 'Must be at most 100 characters';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  key: const Key('save_button'),
                  onPressed: (isSaving || isUploading) ? null : onSave,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _LogoPreview extends StatelessWidget {
  const _LogoPreview({this.logoUrl, required this.name});
  final String? logoUrl;
  final String name;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null) {
      return CircleAvatar(
        radius: 40,
        backgroundImage: NetworkImage(logoUrl!),
        backgroundColor: Colors.grey.shade200,
        onBackgroundImageError: (_, __) {},
      );
    }
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 40,
      backgroundColor: colorScheme.primaryContainer,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
