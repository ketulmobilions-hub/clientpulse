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

    final contextPanel = _ContextPanel(isEdit: isEdit);
    final formCard = _buildFormCard(context, isEdit, disabled);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Project' : 'New Project'),
      ),
      body: _loadingProject
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 4, child: contextPanel),
                                const SizedBox(width: 32),
                                Expanded(flex: 6, child: formCard),
                              ],
                            )
                          : Column(
                              children: [
                                contextPanel,
                                const SizedBox(height: 24),
                                formCard,
                              ],
                            );
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildFormCard(BuildContext context, bool isEdit, bool disabled) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceVariant
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? theme.colorScheme.outline
              : theme.colorScheme.outlineVariant,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _LabeledField(
                label: 'Project Name',
                required: true,
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Acme Website Redesign',
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !disabled,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'Client Name',
                required: true,
                child: TextFormField(
                  controller: _clientNameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Full name or company',
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !disabled,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'Client Email',
                required: true,
                child: TextFormField(
                  controller: _clientEmailCtrl,
                  decoration: const InputDecoration(
                    hintText: 'name@company.com',
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
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'Description',
                helper: 'Brief summary your client will see',
                child: TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(
                    hintText: 'What is this project about?',
                  ),
                  maxLines: 3,
                  enabled: !disabled,
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 20),
                _LabeledField(
                  label: 'Status',
                  required: true,
                  child: DropdownButtonFormField<ProjectStatus>(
                    value: _status,
                    items: ProjectStatus.values
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(_statusLabel(s)),
                            ))
                        .toList(),
                    onChanged:
                        disabled ? null : (v) => setState(() => _status = v!),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _LabeledField(
                label: 'Start Date',
                child: _DatePickerField(
                  placeholder: 'Select start date',
                  value: _startDate,
                  enabled: !disabled,
                  onTap: () => _pickDate(isStart: true),
                  onClear: () => setState(() {
                    _startDate = null;
                    _startDateCleared = true;
                  }),
                ),
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'Expected End Date',
                child: _DatePickerField(
                  placeholder: 'Select end date',
                  value: _expectedEndDate,
                  enabled: !disabled,
                  onTap: () => _pickDate(isStart: false),
                  onClear: () => setState(() {
                    _expectedEndDate = null;
                    _expectedEndDateCleared = true;
                  }),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: disabled ? null : _submit,
                child: _submitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
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

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.isEdit});

  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final title = isEdit ? 'Update this client workspace' : 'Create a new client workspace';
    final subtitle = isEdit
        ? 'Adjust details, dates, and status. Changes are visible to the client.'
        : 'Spin up a dedicated space for your client and start collaborating today.';

    const bullets = <_ContextBullet>[
      _ContextBullet(icon: Icons.bolt_outlined, text: 'Share progress updates'),
      _ContextBullet(icon: Icons.flag_outlined, text: 'Track milestones'),
      _ContextBullet(icon: Icons.check_circle_outline, text: 'Collect approvals'),
      _ContextBullet(icon: Icons.lock_outline, text: 'Private link, no client login'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              isEdit ? 'Edit project' : 'New project',
              style: theme.textTheme.labelSmall?.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ...bullets.map((b) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(b.icon, size: 18, color: primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          b.text,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ContextBullet {
  const _ContextBullet({required this.icon, required this.text});
  final IconData icon;
  final String text;
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.required = false,
    this.helper,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RichText(
          text: TextSpan(
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(text: label),
              if (required)
                TextSpan(
                  text: ' *',
                  semanticsLabel: ' required',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 2),
          Text(
            helper!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({
    required this.placeholder,
    required this.value,
    required this.enabled,
    required this.onTap,
    required this.onClear,
  });

  final String placeholder;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null;
    final display = hasValue ? _format(value!) : placeholder;
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final semanticLabel = hasValue
        ? '$display selected, double tap to change date'
        : '$placeholder, double tap to choose a date';

    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      explicitChildNodes: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: InputDecorator(
          decoration: InputDecoration(
            prefixIcon: ExcludeSemantics(
              child: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: hasValue ? theme.colorScheme.primary : mutedColor,
              ),
            ),
            suffixIcon: hasValue
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    tooltip: 'Clear',
                    onPressed: enabled ? onClear : null,
                  )
                : ExcludeSemantics(
                    child: Icon(Icons.expand_more, size: 20, color: mutedColor),
                  ),
          ),
          child: ExcludeSemantics(
            child: Text(
              display,
              style: TextStyle(
                color: hasValue ? theme.colorScheme.onSurface : mutedColor,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
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
