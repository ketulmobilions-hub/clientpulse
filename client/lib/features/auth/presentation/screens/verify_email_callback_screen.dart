import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:clientpulse/core/router/route_names.dart';
import 'package:clientpulse/core/theme/content_widths.dart';
import 'package:clientpulse/shared/providers/auth_service_provider.dart';
import 'package:clientpulse/shared/services/auth_service.dart';
import 'package:clientpulse/shared/widgets/buttons/app_button.dart';

/// Lands here from the verification email's link. Consumes the token via the
/// backend, then auto-redirects to /login with a "verified" success banner +
/// prefilled email.
class VerifyEmailCallbackScreen extends ConsumerStatefulWidget {
  const VerifyEmailCallbackScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<VerifyEmailCallbackScreen> createState() =>
      _VerifyEmailCallbackScreenState();
}

class _VerifyEmailCallbackScreenState
    extends ConsumerState<VerifyEmailCallbackScreen> {
  _State _phase = const _Loading();
  Timer? _redirect;

  @override
  void initState() {
    super.initState();
    // Empty token = malformed/missing link. Skip the network round-trip.
    if (widget.token.trim().isEmpty) {
      _phase = const _Failed('This verification link is missing its token.');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  @override
  void dispose() {
    _redirect?.cancel();
    super.dispose();
  }

  Future<void> _verify() async {
    try {
      final svc = await ref.read(authServiceProvider.future);
      final outcome = await svc.verifyEmail(widget.token.trim());
      if (!mounted) return;
      switch (outcome) {
        case VerifyEmailSuccess(:final email):
          setState(() => _phase = _Success(email));
          _redirect = Timer(const Duration(seconds: 2), () {
            if (!mounted) return;
            context.go(
                '${RouteNames.login}?email=${Uri.encodeQueryComponent(email)}&verified=1');
          });
        case VerifyEmailFailure(:final message):
          setState(() => _phase = _Failed(message));
      }
    } on AuthServiceException catch (e) {
      if (!mounted) return;
      setState(() => _phase = _Failed(e.message));
    } catch (_) {
      if (!mounted) return;
      // Don't leak raw exception to UI — could include URLs / stack frames.
      setState(() => _phase = const _Failed('Something went wrong. Try again.'));
    }
  }

  void _goToLogin(String email) {
    // Cancel pending auto-redirect Timer to avoid duplicate history push.
    _redirect?.cancel();
    context.go(
        '${RouteNames.login}?email=${Uri.encodeQueryComponent(email)}&verified=1');
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
                  child: _buildBody(theme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    final phase = _phase;
    if (phase is _Loading) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text('Verifying your email…',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              )),
        ],
      );
    }
    if (phase is _Success) {
      return Column(
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
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(height: 20),
          Text('Email verified',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Text(
            'Sign in to continue. Redirecting in a moment…',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Sign in now',
            onPressed: () => _goToLogin(phase.email),
          ),
        ],
      );
    }
    if (phase is _Failed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Icon(Icons.error_outline_rounded,
                size: 48, color: theme.colorScheme.error),
          ),
          const SizedBox(height: 16),
          Text(
            'Verification failed',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            phase.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Back to sign in',
            onPressed: () => context.go(RouteNames.login),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

sealed class _State {
  const _State();
}

class _Loading extends _State {
  const _Loading();
}

class _Success extends _State {
  final String email;
  const _Success(this.email);
}

class _Failed extends _State {
  final String message;
  const _Failed(this.message);
}
