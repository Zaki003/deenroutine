import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/auth_error_messages.dart';

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
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.createAccountTitle)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: l10n.fullNameLabel),
                validator: (v) => (v == null || v.isEmpty) ? l10n.requiredValidatorError : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: l10n.emailLabel),
                validator: (v) =>
                    (v == null || !v.contains('@')) ? l10n.emailValidatorError : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: InputDecoration(labelText: l10n.passwordLabel),
                obscureText: true,
                validator: (v) =>
                    (v == null || v.length < 6) ? l10n.passwordValidatorError : null,
              ),
              const SizedBox(height: 24),
              if (auth.errorCode != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child:
                      Text(authErrorMessage(l10n, auth.errorCode),
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
                        if (ok && mounted) Navigator.pop(context);
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
