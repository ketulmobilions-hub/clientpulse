import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/core/theme/content_widths.dart';
import 'package:clientpulse/shared/providers/auth_notifier.dart';
import 'package:clientpulse/shared/services/auth_service.dart';
import 'package:clientpulse/shared/utils/validators.dart';
import 'package:clientpulse/shared/widgets/buttons/app_button.dart';
import 'package:clientpulse/shared/widgets/buttons/app_icon_button.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _workspaceCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _confirmFocusNode = FocusNode();
  final _nameFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  int _step = 0;
  String? _errorMessage;
  bool _errorIsEmailExists = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(_clearError);
    _passwordCtrl.addListener(_clearError);
    _confirmPasswordCtrl.addListener(_clearError);
    _nameCtrl.addListener(_clearError);
    _workspaceCtrl.addListener(_clearError);
    // Re-validate confirm whenever password edits — without this, confirm shows stale
    // "Passwords do not match" after the user fixes password, until next submit.
    _passwordCtrl.addListener(_revalidateConfirm);
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_clearError);
    _passwordCtrl.removeListener(_clearError);
    _confirmPasswordCtrl.removeListener(_clearError);
    _nameCtrl.removeListener(_clearError);
    _workspaceCtrl.removeListener(_clearError);
    _passwordCtrl.removeListener(_revalidateConfirm);
    _nameCtrl.dispose();
    _workspaceCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _confirmFocusNode.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _errorMessage == null) return;
      setState(() {
        _errorMessage = null;
        _errorIsEmailExists = false;
      });
    });
  }

  void _revalidateConfirm() {
    // AutovalidateMode.onUserInteraction on the confirm field re-runs its
    // validator on every rebuild after the user first interacts. setState
    // triggers a rebuild, and the validator reads the latest password text.
    if (_confirmPasswordCtrl.text.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  void _continue() {
    if (!(_step1Key.currentState?.validate() ?? false)) return;
    setState(() => _step = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _nameFocusNode.requestFocus();
      SemanticsService.announce('Step 2 of 2', TextDirection.ltr);
    });
  }

  void _back() {
    setState(() => _step = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      SemanticsService.announce('Step 1 of 2', TextDirection.ltr);
    });
  }

  Future<void> _submit() async {
    if (!(_step2Key.currentState?.validate() ?? false)) return;
    if (ref.read(authNotifierProvider).isLoading) return;
    try {
      final outcome = await ref.read(authNotifierProvider.notifier).register(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
            _nameCtrl.text.trim(),
            _workspaceCtrl.text.trim(),
          );
      if (!mounted) return;
      // Register always requires verification now. Sealed switch over the
      // outcome ensures any future variant (e.g. RegisterRateLimited) is a
      // compile-time error here, not a silently-do-nothing else branch.
      switch (outcome) {
        case RegisterRequiresVerification(:final email):
          context.go(
              '${RouteNames.verifyEmailPending}?email=${Uri.encodeQueryComponent(email)}');
      }
    } on AuthServiceException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _errorIsEmailExists = e.isEmailAlreadyExists;
        });
      }
    } on StateError catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _errorIsEmailExists = false;
        });
      }
    }
  }

  bool get _hasUnsavedInput =>
      _emailCtrl.text.isNotEmpty ||
      _passwordCtrl.text.isNotEmpty ||
      _confirmPasswordCtrl.text.isNotEmpty ||
      _nameCtrl.text.isNotEmpty ||
      _workspaceCtrl.text.isNotEmpty;

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard registration?'),
        content: const Text(
            'You have unsaved input. Leave this page and lose what you entered?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _goToLogin() async {
    if (_hasUnsavedInput && !await _confirmDiscard()) return;
    if (!mounted) return;
    context.goNamed(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final surface = theme.colorScheme.surface;
    final viewportWidth = MediaQuery.of(context).size.width;
    final cardPadding = viewportWidth < 360
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 28)
        : const EdgeInsets.all(36);

    return PopScope(
      canPop: !_hasUnsavedInput,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldDiscard = await _confirmDiscard();
        if (shouldDiscard && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.35),
                surface,
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxWidth: AppContentWidth.auth),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    boxShadow: [
                      BoxShadow(
                        color: theme.shadowColor.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: cardPadding,
                    // Both steps stay mounted via Offstage so AutofillGroup can
                    // advertise email + password to the platform when register()
                    // submits from step 2 (otherwise password manager save prompt
                    // never fires). Also preserves focus + controller state.
                    child: AutofillGroup(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: ExcludeSemantics(
                              child: Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.bolt_rounded,
                                    color: Colors.white, size: 30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'ClientPulse',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Manage client updates, approvals & feedback in one place.',
                            key: const Key('value_prop'),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          _StepIndicator(step: _step),
                          const SizedBox(height: 24),
                          if (_errorMessage != null) ...[
                            Semantics(
                              container: true,
                              liveRegion: true,
                              label: 'Registration error: $_errorMessage',
                              child: ExcludeSemantics(
                                child: Container(
                                  key: const Key('error_banner'),
                                  padding: const EdgeInsets.fromLTRB(
                                      12, 10, 12, 10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.error
                                          .withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline_rounded,
                                            size: 18,
                                            color: theme.colorScheme.error,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _errorMessage!,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onErrorContainer,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_errorIsEmailExists)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 28, top: 4),
                                          child: AppButton(
                                            key: const Key(
                                                'sign_in_instead_button'),
                                            label: 'Sign in instead',
                                            variant: AppButtonVariant.tertiary,
                                            size: AppButtonSize.sm,
                                            onPressed: isLoading
                                                ? null
                                                : () => context.goNamed(
                                                      RouteNames.login,
                                                      queryParameters: {
                                                        'email': _emailCtrl
                                                            .text
                                                            .trim(),
                                                      },
                                                    ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Offstage(
                            offstage: _step != 0,
                            child: TickerMode(
                              enabled: _step == 0,
                              child: _buildStep1(theme, isLoading),
                            ),
                          ),
                          Offstage(
                            offstage: _step != 1,
                            child: TickerMode(
                              enabled: _step == 1,
                              child: _buildStep2(theme, isLoading),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            key: const Key('login_link'),
                            label: 'Already have an account? Sign in',
                            variant: AppButtonVariant.tertiary,
                            onPressed: isLoading ? null : _goToLogin,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1(ThemeData theme, bool isLoading) {
    return Form(
      key: _step1Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('email_field'),
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(labelText: 'Email'),
            validator: validateEmail,
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('password_field'),
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            onFieldSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_confirmFocusNode),
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: AppIconButton(
                icon: _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                tooltip:
                    _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (v) {
              final val = v ?? '';
              if (val.isEmpty) return 'Password is required';
              if (val.length < 8) return 'Password must be at least 8 characters';
              if (val.length > 128) {
                return 'Password must be under 128 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('confirm_password_field'),
            controller: _confirmPasswordCtrl,
            focusNode: _confirmFocusNode,
            obscureText: _obscureConfirm,
            textInputAction: TextInputAction.done,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            // No autofill hint on confirm — duplicating newPassword on two fields
            // confuses iOS Keychain / 1Password and degrades save prompts.
            onFieldSubmitted: (_) => _continue(),
            decoration: InputDecoration(
              labelText: 'Confirm Password',
              suffixIcon: AppIconButton(
                icon: _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                tooltip:
                    _obscureConfirm ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Please confirm your password';
              if (v != _passwordCtrl.text) return 'Passwords do not match';
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            key: const Key('continue_button'),
            label: 'Continue',
            size: AppButtonSize.lg,
            fullWidth: true,
            onPressed: isLoading ? null : _continue,
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme, bool isLoading) {
    return Form(
      key: _step2Key,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            key: const Key('name_field'),
            controller: _nameCtrl,
            focusNode: _nameFocusNode,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(labelText: 'Full Name'),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'Name is required';
              if (val.length > 100) return 'Name must be under 100 characters';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            key: const Key('workspace_field'),
            controller: _workspaceCtrl,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
                labelText: 'Agency / Workspace Name'),
            onFieldSubmitted: (_) => _submit(),
            validator: (v) {
              final val = v?.trim() ?? '';
              if (val.isEmpty) return 'Workspace name is required';
              if (val.length > 100) {
                return 'Workspace name must be under 100 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            key: const Key('register_button'),
            label: 'Create Account',
            size: AppButtonSize.lg,
            fullWidth: true,
            loading: isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 8),
          AppButton(
            key: const Key('back_button'),
            label: 'Back',
            variant: AppButtonVariant.tertiary,
            onPressed: isLoading ? null : _back,
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = theme.colorScheme.primary;
    final inactive = theme.colorScheme.outlineVariant;

    return Semantics(
      container: true,
      label: 'Registration progress, step ${step + 1} of 2',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: active,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: step == 1 ? active : inactive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Step ${step + 1} of 2',
              key: const Key('step_indicator'),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
