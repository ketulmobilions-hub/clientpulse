import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/breakpoints.dart';
import '../../../../core/theme/content_widths.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../shared/models/project.dart';
import '../../../../shared/providers/project_provider.dart';
import '../../../../shared/services/project_service.dart';
import '../../../../shared/utils/history_back_stub.dart'
    if (dart.library.html) '../../../../shared/utils/history_back_web.dart';

class CreateEditProjectScreen extends ConsumerStatefulWidget {
  const CreateEditProjectScreen({
    super.key,
    this.projectId,
    this.cameFromInApp = false,
  });

  final String? projectId;

  /// True when this screen was reached via an in-app navigation that pushed
  /// a single browser history entry we can walk back over (e.g. Dashboard's
  /// "New Project" button or Project Detail's edit pencil — both pass
  /// `extra: true` through the router). On submit, this signals it's safe
  /// to call `history.back()` instead of `goNamed`, so the cursor walks
  /// over the create/edit entry rather than appending a new one (which
  /// would let the browser back button re-show this screen). Deep links
  /// and fresh tabs leave it false so the submit handler falls back to
  /// declarative `goNamed` navigation.
  final bool cameFromInApp;

  bool get isEdit => projectId != null;

  @override
  ConsumerState<CreateEditProjectScreen> createState() =>
      _CreateEditProjectScreenState();
}

class _CreateEditProjectScreenState
    extends ConsumerState<CreateEditProjectScreen> {
  static final _emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

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
      final project = await ref
          .read(projectNotifierProvider.notifier)
          .getProject(widget.projectId!);
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

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    if (!_emailRegExp.hasMatch(v.trim())) return 'Enter a valid email';
    return null;
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
              description:
                  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              clearDescription: _descCtrl.text.trim().isEmpty,
              status: _status,
              startDate: _startDate,
              clearStartDate: _startDateCleared,
              expectedEndDate: _expectedEndDate,
              clearExpectedEndDate: _expectedEndDateCleared,
            );
        if (mounted) {
          // Keep _submitting=true through the nav. history.back() dispatches
          // popstate on the next event-loop tick; resetting before that would
          // re-enable the Save button and allow a double-submit.
          if (!(widget.cameFromInApp && historyBack())) {
            context.goNamed(
              RouteNames.projectDetail,
              pathParameters: {'id': widget.projectId!},
            );
          }
        }
      } else {
        final project = await ref.read(projectNotifierProvider.notifier).create(
              name: _nameCtrl.text.trim(),
              clientName: _clientNameCtrl.text.trim(),
              clientEmail: _clientEmailCtrl.text.trim(),
              description:
                  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              startDate: _startDate,
              expectedEndDate: _expectedEndDate,
            );
        if (mounted) {
          // Reset before the share dialog opens so a dialog dismiss (e.g. ESC)
          // leaves the form interactive instead of stuck with Save disabled.
          setState(() => _submitting = false);
          _showShareDialog(project);
        }
      }
    } on ProjectServiceException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      if (!(widget.cameFromInApp && historyBack())) {
        context.goNamed(RouteNames.dashboard);
      }
      return;
    }

    final portalUrl = '${AppConstants.appBaseUrl}/p/$shareToken';
    // Capture ScaffoldMessengerState before the dialog opens — the outer context
    // may be deactivated by context.goNamed() before the copy snackbar fires.
    final messenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        final dialogTheme = Theme.of(dialogCtx);
        return AlertDialog(
          title: const Text('Project Created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Share this link with your client:'),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: dialogTheme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: dialogTheme.colorScheme.outlineVariant),
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
                if (!(widget.cameFromInApp && historyBack())) {
                  context.goNamed(RouteNames.dashboard);
                }
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;
    final disabled = _submitting || _loadingProject;

    final contextPanel = _ContextPanel(isEdit: isEdit);
    final formCard = _FormCard(
      formKey: _formKey,
      isEdit: isEdit,
      disabled: disabled,
      submitting: _submitting,
      nameCtrl: _nameCtrl,
      clientNameCtrl: _clientNameCtrl,
      clientEmailCtrl: _clientEmailCtrl,
      descCtrl: _descCtrl,
      status: _status,
      startDate: _startDate,
      expectedEndDate: _expectedEndDate,
      emailValidator: _validateEmail,
      onStatusChanged: (v) => setState(() => _status = v),
      onPickStart: () => _pickDate(isStart: true),
      onPickEnd: () => _pickDate(isStart: false),
      onClearStart: () => setState(() {
        _startDate = null;
        _startDateCleared = true;
      }),
      onClearEnd: () => setState(() {
        _expectedEndDate = null;
        _expectedEndDateCleared = true;
      }),
      onSubmit: _submit,
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(isEdit ? 'Edit Project' : 'New Project'),
      ),
      body: _loadingProject
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s24, vertical: AppSpacing.s32),
              child: Center(
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppContentWidth.standard),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide =
                          constraints.maxWidth >= AppBreakpoints.tablet;
                      return isWide
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 4, child: contextPanel),
                                const SizedBox(width: AppSpacing.s32),
                                Expanded(flex: 6, child: formCard),
                              ],
                            )
                          : Column(
                              children: [
                                contextPanel,
                                const SizedBox(height: AppSpacing.s24),
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
}

String _statusLabel(ProjectStatus s) => switch (s) {
      ProjectStatus.active => 'Active',
      ProjectStatus.completed => 'Completed',
      ProjectStatus.archived => 'Archived',
    };

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.formKey,
    required this.isEdit,
    required this.disabled,
    required this.submitting,
    required this.nameCtrl,
    required this.clientNameCtrl,
    required this.clientEmailCtrl,
    required this.descCtrl,
    required this.status,
    required this.startDate,
    required this.expectedEndDate,
    required this.emailValidator,
    required this.onStatusChanged,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onClearStart,
    required this.onClearEnd,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final bool isEdit;
  final bool disabled;
  final bool submitting;
  final TextEditingController nameCtrl;
  final TextEditingController clientNameCtrl;
  final TextEditingController clientEmailCtrl;
  final TextEditingController descCtrl;
  final ProjectStatus status;
  final DateTime? startDate;
  final DateTime? expectedEndDate;
  final FormFieldValidator<String> emailValidator;
  final ValueChanged<ProjectStatus> onStatusChanged;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final VoidCallback onClearStart;
  final VoidCallback onClearEnd;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : theme.colorScheme.surface,
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
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SectionHeader(label: 'Basic Info'),
              _LabeledField(
                label: 'Project Name',
                required: true,
                child: TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Acme Website Redesign',
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !disabled,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Client Name',
                required: true,
                child: TextFormField(
                  controller: clientNameCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Full name or company',
                  ),
                  textInputAction: TextInputAction.next,
                  enabled: !disabled,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Client Email',
                required: true,
                child: TextFormField(
                  controller: clientEmailCtrl,
                  decoration: const InputDecoration(
                    hintText: 'name@company.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !disabled,
                  validator: emailValidator,
                ),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Description',
                helper: 'Brief summary your client will see',
                child: TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    hintText: 'What is this project about?',
                  ),
                  maxLines: 3,
                  enabled: !disabled,
                ),
              ),
              const SizedBox(height: 16),
              const _SectionHeader(label: 'Timeline'),
              _LabeledField(
                label: 'Start Date',
                child: _DatePickerField(
                  placeholder: 'Select start date',
                  value: startDate,
                  enabled: !disabled,
                  onTap: onPickStart,
                  onClear: onClearStart,
                ),
              ),
              const SizedBox(height: 16),
              _LabeledField(
                label: 'Expected End Date',
                child: _DatePickerField(
                  placeholder: 'Select end date',
                  value: expectedEndDate,
                  enabled: !disabled,
                  onTap: onPickEnd,
                  onClear: onClearEnd,
                ),
              ),
              if (isEdit) ...[
                const SizedBox(height: 16),
                const _SectionHeader(label: 'Status'),
                DropdownButtonFormField<ProjectStatus>(
                  value: status,
                  items: ProjectStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(_statusLabel(s)),
                          ))
                      .toList(),
                  onChanged: disabled
                      ? null
                      : (v) {
                          if (v != null) onStatusChanged(v);
                        },
                ),
              ],
              const SizedBox(height: 28),
              isEdit
                  ? FilledButton.tonal(
                      onPressed: disabled ? null : onSubmit,
                      child: submitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                            )
                          : const Text('Save Changes'),
                    )
                  : FilledButton(
                      onPressed: disabled ? null : onSubmit,
                      child: submitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.colorScheme.onPrimary,
                              ),
                            )
                          : const Text('Create Project'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContextPanel extends StatelessWidget {
  const _ContextPanel({required this.isEdit});

  final bool isEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final title = isEdit
        ? 'Update this client workspace'
        : 'Create a new client workspace';
    final subtitle = isEdit
        ? 'Adjust details, dates, and status. Changes are visible to the client.'
        : 'Spin up a dedicated space for your client and start collaborating today.';

    const bullets = <_ContextBullet>[
      _ContextBullet(icon: Icons.bolt_outlined, text: 'Share progress updates'),
      _ContextBullet(icon: Icons.flag_outlined, text: 'Track milestones'),
      _ContextBullet(
          icon: Icons.check_circle_outline, text: 'Collect approvals'),
      _ContextBullet(
          icon: Icons.lock_outline, text: 'Private link, no client login'),
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Semantics(
            header: true,
            child: Text(
              label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ExcludeSemantics(
              child: Container(
                height: 1,
                color: theme.colorScheme.outlineVariant.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
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

  // Pin to en_US — `intl` ships en_US data built-in, other locales require
  // `initializeDateFormatting()` at app startup which isn't wired yet.
  static final _formatter = DateFormat.yMMMd('en_US');

  final String placeholder;
  final DateTime? value;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasValue = value != null;
    final display = hasValue ? _formatter.format(value!) : placeholder;
    final mutedColor = theme.colorScheme.onSurfaceVariant;
    final disabledColor = theme.colorScheme.onSurface.withOpacity(0.38);
    final iconColor = !enabled
        ? disabledColor
        : (hasValue ? theme.colorScheme.primary : mutedColor);
    final textColor = !enabled
        ? disabledColor
        : (hasValue ? theme.colorScheme.onSurface : mutedColor);
    final semanticLabel = hasValue
        ? '$display selected, double tap to change date'
        : '$placeholder, double tap to choose a date';

    return MergeSemantics(
      child: Semantics(
        button: true,
        enabled: enabled,
        label: semanticLabel,
        onTap: enabled ? onTap : null,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(10),
          excludeFromSemantics: true,
          child: InputDecorator(
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: iconColor,
              ),
              suffixIcon: hasValue
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      tooltip: 'Clear',
                      onPressed: enabled ? onClear : null,
                    )
                  : Icon(Icons.expand_more, size: 20, color: iconColor),
            ),
            child: Text(
              display,
              style: TextStyle(
                color: textColor,
                fontWeight: hasValue ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
