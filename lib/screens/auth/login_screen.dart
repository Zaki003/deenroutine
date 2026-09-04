import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/auth_error_messages.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mosque,
                        size: 64, color: Theme.of(context).colorScheme.success),
                    const SizedBox(height: 12),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: InputDecoration(labelText: l10n.emailLabel),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? l10n.emailValidatorError
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration:
                          InputDecoration(labelText: l10n.passwordLabel),
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
                              await auth.login(_emailCtrl.text.trim(),
                                  _passwordCtrl.text.trim());
                            },
                      child: auth.isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.loginButton),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RegisterScreen()),
                      ),
                      child: Text(l10n.registerPrompt),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
