import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';

/// Password-confirmation dialog for the in-app account-deletion path
/// (Play Store data-deletion requirement). Pops `true` only once the
/// account and all its data are actually gone; pops `false`/`null` on
/// cancel/dismiss. A failed attempt (e.g. wrong password) stays open with
/// an inline error instead of closing, matching LoginScreen's pattern.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _submitting = false;
  // Local, not AuthProvider.errorCode: AuthProvider is a long-lived
  // singleton, so reading its errorCode reactively here would show a
  // *stale* error from an earlier cancelled attempt the instant this
  // dialog reopens, before the user has typed or submitted anything.
  String? _errorCode;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorCode = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.deleteAccount(_passwordCtrl.text);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _errorCode = ok ? null : auth.errorCode;
    });
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final errorColor = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: Text(l10n.deleteAccountTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountWarning),
            const SizedBox(height: 16),
            Text(l10n.deleteAccountPasswordPrompt),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.passwordLabel,
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) => (v == null || v.isEmpty) ? l10n.requiredValidatorError : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_errorCode != null) ...[
              const SizedBox(height: 8),
              Text(
                authErrorMessage(l10n, _errorCode),
                style: TextStyle(color: errorColor, fontSize: 12.5),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancelButton),
        ),
        TextButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.deleteAccountButton, style: TextStyle(color: errorColor)),
        ),
      ],
    );
  }
}
