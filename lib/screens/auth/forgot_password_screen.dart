import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../utils/auth_error_messages.dart';
import '../../utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.resetPasswordTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _sent ? _buildSentView(context, l10n) : _buildForm(context, auth, l10n),
      ),
    );
  }

  Widget _buildForm(BuildContext context, AuthProvider auth, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.resetPasswordPrompt),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailCtrl,
            decoration: InputDecoration(labelText: l10n.emailLabel),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || !isValidEmail(v)) ? l10n.emailValidatorError : null,
          ),
          const SizedBox(height: 24),
          if (auth.errorCode != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(authErrorMessage(l10n, auth.errorCode),
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          FilledButton(
            onPressed: auth.isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    final ok = await auth.resetPassword(_emailCtrl.text.trim());
                    if (ok && mounted) setState(() => _sent = true);
                  },
            child: auth.isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.sendResetLinkButton),
          ),
        ],
      ),
    );
  }

  Widget _buildSentView(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 64, color: Theme.of(context).colorScheme.success),
        const SizedBox(height: 16),
        Text(
          l10n.resetLinkSentTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.resetLinkSentMessage(_emailCtrl.text.trim()),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.loginButton),
        ),
      ],
    );
  }
}
