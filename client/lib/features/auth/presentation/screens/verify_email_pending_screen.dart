import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/core/theme/content_widths.dart';
import 'package:clientpulse/shared/providers/auth_service_provider.dart';
import 'package:clientpulse/shared/services/auth_service.dart';
import 'package:clientpulse/shared/widgets/buttons/app_button.dart';

/// Shown after register or after a login attempt against an unverified account.
/// Tells the user to check their email + lets them resend with a 60s cooldown.
class VerifyEmailPendingScreen extends ConsumerStatefulWidget {
  const VerifyEmailPendingScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailPendingScreen> createState() =>
      _VerifyEmailPendingScreenState();
}

class _VerifyEmailPendingScreenState
    extends ConsumerState<VerifyEmailPendingScreen> {
  // Mirrors VERIFICATION_RESEND_COOLDOWN_MS in server/src/services/auth.service.ts.
  // Keep in sync — server enforces silently, client shows the countdown.
  static const _cooldownSeconds = 60;
  DateTime? _cooldownEndsAt;
  int _remaining = _cooldownSeconds;
  Timer? _ticker;
  bool _resending = false;
  String? _info;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _ticker?.cancel();
    final endsAt = DateTime.now().add(const Duration(seconds: _cooldownSeconds));
    setState(() {
      _cooldownEndsAt = endsAt;
      _remaining = _cooldownSeconds;
    });
    // Tick on wall-clock diff so a backgrounded tab returning after the
    // cooldown should have expired sees 0, not the throttled-tick count.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final remaining = _cooldownEndsAt!.difference(DateTime.now()).inSeconds;
      setState(() {
        _remaining = remaining > 0 ? remaining : 0;
        if (_remaining <= 0) _ticker?.cancel();
      });
    });
  }

  Future<void> _resend() async {
    if (_resending || _remaining > 0 || widget.email.isEmpty) return;
    setState(() {
      _resending = true;
      _info = null;
      _error = null;
    });
    try {
      final svc = await ref.read(authServiceProvider.future);
      await svc.resendVerification(widget.email);
      if (!mounted) return;
      setState(() {
        _info = 'Verification email sent. Check your inbox.';
      });
      _startCooldown();
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
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
              constraints: const BoxConstraints(maxWidth: AppContentWidth.auth),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.mark_email_unread_outlined,
                              color: Colors.white, size: 28),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Check your email',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          children: [
                            const TextSpan(
                                text: 'We sent a verification link to '),
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const TextSpan(
                                text:
                                    '. Click the link in that email to finish setting up your account.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Check spam — emails can take up to a minute to arrive.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_info != null) ...[
                        const SizedBox(height: 20),
                        _Banner(
                          color: theme.colorScheme.primaryContainer,
                          textColor: theme.colorScheme.onPrimaryContainer,
                          icon: Icons.check_circle_outline_rounded,
                          message: _info!,
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 20),
                        _Banner(
                          color: theme.colorScheme.errorContainer,
                          textColor: theme.colorScheme.onErrorContainer,
                          icon: Icons.error_outline_rounded,
                          message: _error!,
                        ),
                      ],
                      const SizedBox(height: 28),
                      AppButton(
                        label: _remaining > 0
                            ? 'Resend in ${_remaining}s'
                            : 'Resend verification email',
                        icon: Icons.refresh_rounded,
                        loading: _resending,
                        onPressed:
                            _remaining > 0 || _resending ? null : _resend,
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Back to sign in',
                        variant: AppButtonVariant.tertiary,
                        onPressed: () => context.go(RouteNames.login),
                      ),
                    ],
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

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.textColor,
    required this.icon,
    required this.message,
  });

  final Color color;
  final Color textColor;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
