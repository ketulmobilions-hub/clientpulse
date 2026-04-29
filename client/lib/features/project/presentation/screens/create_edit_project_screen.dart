import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants.dart';
import '../../../../shared/models/project.dart';
import '../../../../shared/providers/project_provider.dart';
import '../../../../shared/services/project_service.dart';

class CreateEditProjectScreen extends ConsumerStatefulWidget {
  const CreateEditProjectScreen({super.key, this.projectId});

  final String? projectId;

  bool get isEdit => projectId != null;

  @override
  ConsumerState<CreateEditProjectScreen> createState() => _CreateEditProjectScreenState();
}

class _CreateEditProjectScreenState extends ConsumerState<CreateEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  ProjectStatus _status = ProjectStatus.active;
  DateTime? _startDate;
  DateTime? _expectedEndDate;

  // Track explicit user clears so we only send null-clear to the API
  // when the user deliberately removed a date, not just because it was never set.
  bool _startDateCleared = false;
  bool _expectedEndDateCleared = false;

  bool _loadingProject = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadProject());
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProject() async {
    setState(() => _loadingProject = true);
    try {
      final project =
          await ref.read(projectNotifierProvider.notifier).getProject(widget.projectId!);
      if (!mounted) return;
      _nameCtrl.text = project.name;
      _clientNameCtrl.text = project.clientName;
      _clientEmailCtrl.text = project.clientEmail;
      _descCtrl.text = project.description ?? '';
      setState(() {
        _status = project.status;
        _startDate = project.startDate;
        _expectedEndDate = project.expectedEndDate;
        _startDateCleared = false;
        _expectedEndDateCleared = false;
        _loadingProject = false;
      });
    } on ProjectServiceException catch (e) {
      if (!mounted) return;
      setState(() => _loadingProject = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load project: ${e.message}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProject = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load project: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_expectedEndDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        _startDateCleared = false;
      } else {
        _expectedEndDate = picked;
        _expectedEndDateCleared = false;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Cross-field date ordering validation (not expressible in FormField validators).
    if (_startDate != null &&
        _expectedEndDate != null &&
        _expectedEndDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expected end date must be on or after start date'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      if (widget.isEdit) {
        await ref.read(projectNotifierProvider.notifier).updateProject(
              widget.projectId!,
              name: _nameCtrl.text.trim(),
              clientName: _clientNameCtrl.text.trim(),
              clientEmail: _clientEmailCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              clearDescription: _descCtrl.text.trim().isEmpty,
              status: _status,
              startDate: _startDate,
              clearStartDate: _startDateCleared,
              expectedEndDate: _expectedEndDate,
              clearExpectedEndDate: _expectedEndDateCleared,
            );
        if (mounted) {
          setState(() => _submitting = false);
          context.pop();
        }
      } else {
        final project = await ref.read(projectNotifierProvider.notifier).create(
              name: _nameCtrl.text.trim(),
              clientName: _clientNameCtrl.text.trim(),
              clientEmail: _clientEmailCtrl.text.trim(),
              description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              startDate: _startDate,
              expectedEndDate: _expectedEndDate,
            );
        if (mounted) _showShareDialog(project);
      }
    } on ProjectServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showShareDialog(Project project) {
    final shareToken = project.shareToken;

    // Guard: backend should always return a share_token, but handle null defensively.
    if (shareToken == null || shareToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Project created'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/dashboard');
      return;
    }

    final portalUrl = '${AppConstants.appBaseUrl}/p/$shareToken';
    // Capture ScaffoldMessengerState before the dialog opens — the outer context
    // may be deactivated by context.go() before the copy snackbar fires.
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Project Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this link with your client:'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      portalUrl,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18),
                    tooltip: 'Copy link',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: portalUrl));
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Link copied'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.go('/dashboard');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;
    final disabled = _submitting || _loadingProject;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Project' : 'New Project'),
      ),
      body: _loadingProject
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Project Name *',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      enabled: !disabled,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clientNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Client Name *',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.next,
                      enabled: !disabled,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _clientEmailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Client Email *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !disabled,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      enabled: !disabled,
                    ),
                    if (isEdit) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<ProjectStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status *',
                          border: OutlineInputBorder(),
                        ),
                        items: ProjectStatus.values
                            .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(_statusLabel(s)),
                                ))
                            .toList(),
                        onChanged: disabled ? null : (v) => setState(() => _status = v!),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _DatePickerField(
                      label: 'Start Date',
                      value: _startDate,
                      enabled: !disabled,
                      onTap: () => _pickDate(isStart: true),
                      onClear: () => setState(() {
                        _startDate = null;
                        _startDateCleared = true;
                      }),
                    ),
                    const SizedBox(height: 16),
                    _DatePickerField(
                      label: 'Expected End Date',
                      value: _expectedEndDate,
                      enabled: !disabled,
                      onTap: () => _pickDate(isStart: false),
                      onClear: () => setState(() {
                        _expectedEndDate = null;
                        _expectedEndDateCleared = true;
                      }),
                    ),
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: disabled ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEdit ? 'Save Changes' : 'Create Project'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _statusLabel(ProjectStatus s) => switch (s) {
        ProjectStatus.active => 'Active',
        ProjectStatus.completed => 'Completed',
        ProjectStatus.archived => 'Archived',
      };
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final display = value != null ? _format(value!) : 'Not set';
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: value != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: enabled ? onClear : null,
                )
              : const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          display,
          style: TextStyle(
            color: value != null ? null : Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  String _format(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
