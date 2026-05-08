import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/utils/validators.dart';
import '../../data/waitlist_repository.dart';
import '../../providers/waitlist_provider.dart';
import '../theme/landing_theme.dart';

class WaitlistForm extends ConsumerStatefulWidget {
  const WaitlistForm({super.key});

  @override
  ConsumerState<WaitlistForm> createState() => _WaitlistFormState();
}

class _WaitlistFormState extends ConsumerState<WaitlistForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(waitlistControllerProvider.notifier)
        .submit(email: _emailCtrl.text.trim());
    if (!mounted) return;
    final state = ref.read(waitlistControllerProvider);
    state.when(
      data: (_) => setState(() => _submitted = true),
      loading: () {},
      error: (e, _) {
        final msg = e is WaitlistException ? e.message : 'Something went wrong.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(waitlistControllerProvider);
    final loading = state.isLoading;

    if (_submitted) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          "You're on the list. We'll email you the moment it's live.",
          style: TextStyle(
            color: LandingColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stack = constraints.maxWidth < 480;
          final emailField = TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            validator: validateEmail,
            enabled: !loading,
            decoration: const InputDecoration(hintText: 'you@agency.com'),
          );
          final button = FilledButton(
            onPressed: loading ? null : _onSubmit,
            child: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Notify me on launch →'),
          );
          if (stack) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                emailField,
                const SizedBox(height: 12),
                button,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: emailField),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }
}
