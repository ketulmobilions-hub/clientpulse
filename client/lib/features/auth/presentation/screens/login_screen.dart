import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clientpulse/shared/providers/auth_notifier.dart';
import 'package:clientpulse/shared/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Clear inline error once the user starts editing — keeps error banner aligned with intent.
    _emailCtrl.addListener(_clearError);
    _passwordCtrl.addListener(_clearError);
  }

  @override
  void dispose() {
    _emailCtrl.removeListener(_clearError);
    _passwordCtrl.removeListener(_clearError);
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage == null) return;
    // Defer to post-frame: TextEditingController fires listeners synchronously, which can
    // land mid-build (autofill, IME composition, programmatic .text=). setState during build
    // throws an assertion; the post-frame callback skips the same-frame race.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _errorMessage == null) return;
      setState(() => _errorMessage = null);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    // Re-entrancy guard: Enter key on the password field can re-trigger _submit while a
    // previous login is still awaiting. AuthNotifier.login throws StateError on overlap;
    // bail early here so the user-facing banner reflects real auth errors, not the overlap.
    if (ref.read(authNotifierProvider).isLoading) return;
    // Do NOT pre-clear _errorMessage — that flashes the banner off then back on for slow
    // logins. Input listener clears on edit; success path replaces UI entirely.
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .login(_emailCtrl.text.trim(), _passwordCtrl.text);
    } on AuthServiceException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } on StateError catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    }
  }

  void _handleForgotPassword() {
    // Password reset flow not implemented yet. Honest copy only — no fake support email
    // (Resend account not yet set up per project setup notes).
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(const SnackBar(
        content: Text('Password reset is coming soon.'),
        duration: Duration(seconds: 3),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(authNotifierProvider).isLoading;
    final surface = theme.colorScheme.surface;
    // Trim inner card padding on very narrow viewports (e.g. foldable cover, 320px Android Chrome)
    // so long error messages don't squeeze the banner text below readable width.
    final viewportWidth = MediaQuery.of(context).size.width;
    final cardPadding = viewportWidth < 360
        ? const EdgeInsets.symmetric(horizontal: 20, vertical: 28)
        : const EdgeInsets.all(36);

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            // Theme-aware: top stop uses primaryContainer (light tint in light mode,
            // dark accent in dark mode); bottom anchors at the surface color.
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
              constraints: const BoxConstraints(maxWidth: 420),
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
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 30),
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
                            'Private workspace for client updates',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          if (_errorMessage != null) ...[
                            // liveRegion + container: screen readers announce the new error
                            // when it appears (sighted users see the red banner; SR users
                            // would otherwise get nothing since focus doesn't move).
                            Semantics(
                              container: true,
                              liveRegion: true,
                              label: 'Login error: $_errorMessage',
                              child: ExcludeSemantics(
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.error.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
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
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onErrorContainer,
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
                          TextFormField(
                            key: const Key('email_field'),
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            key: const Key('password_field'),
                            controller: _passwordCtrl,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePassword = !_obscurePassword),
                                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                              ),
                            ),
                            validator: (v) =>
                                (v?.isEmpty ?? true) ? 'Password is required' : null,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              key: const Key('forgot_password_link'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: isLoading ? null : _handleForgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            key: const Key('login_button'),
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sign in to workspace'),
                          ),
                          const SizedBox(height: 12),
                          // Trust signal — placed under CTA so it reinforces the action.
                          // Wrap (not Row) so it folds onto a second line on narrow viewports.
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 5,
                            runSpacing: 2,
                            children: [
                              // Decorative — screen reader announces only the trust copy below.
                              ExcludeSemantics(
                                child: Icon(
                                  Icons.lock_outline_rounded,
                                  size: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                'Built for service-based agencies',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            key: const Key('register_link'),
                            onPressed: () => context.go('/register'),
                            child: const Text("Don't have an account? Register"),
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
}

String? _validateEmail(String? v) {
  final val = v?.trim() ?? '';
  if (val.isEmpty) return 'Email is required';
  final atIndex = val.indexOf('@');
  if (atIndex <= 0) return 'Enter a valid email address';
  final domain = val.substring(atIndex + 1);
  if (domain.isEmpty || !domain.contains('.') || domain.endsWith('.')) {
    return 'Enter a valid email address';
  }
  return null;
}
