import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/auth_error_messages.dart';
import '../../utils/validators.dart';
import '../onboarding/onboarding_welcome_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Otherwise a failed login's error message is still showing here the
    // moment this screen opens, before the user has typed anything.
    context.read<AuthProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createAccountTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: l10n.fullNameLabel),
                validator: (v) {
                  final name = v?.trim() ?? '';
                  if (name.isEmpty) return l10n.requiredValidatorError;
                  // Catches "018"-style nonsense without rejecting real
                  // names in non-Latin scripts (Bangla, etc.) - \p{L} is
                  // Unicode "any letter", not just a-z.
                  if (!RegExp(r'\p{L}', unicode: true).hasMatch(name)) {
                    return l10n.fullNameValidatorError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                validator: (v) => (v == null || !isValidEmail(v))
                    ? l10n.emailValidatorError
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                obscureText: true,
                validator: (v) => (v == null || v.length < 6)
                    ? l10n.passwordValidatorError
                    : null,
              ),
              const SizedBox(height: 24),
              if (auth.errorCode != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(authErrorMessage(l10n, auth.errorCode),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton(
                onPressed: auth.isLoading
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) return;
                        final ok = await auth.register(
                          _nameCtrl.text.trim(),
                          _emailCtrl.text.trim(),
                          _passwordCtrl.text.trim(),
                        );
                        if (!ok || !context.mounted) return;
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (_) => const OnboardingWelcomeScreen()),
                        );
                      },
                child: Text(l10n.registerButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
