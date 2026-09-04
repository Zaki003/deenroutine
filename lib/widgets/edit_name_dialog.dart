import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_error_messages.dart';

/// Simple rename dialog for the Profile screen. Pops `true` once the name
/// is actually saved; `false`/`null` on cancel/dismiss, matching
/// [DeleteAccountDialog]'s convention.
class EditNameDialog extends StatefulWidget {
  final String currentName;

  const EditNameDialog({super.key, required this.currentName});

  @override
  State<EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<EditNameDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.currentName);
  bool _submitting = false;
  String? _errorCode;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _errorCode = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(name: _nameCtrl.text.trim());
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
      title: Text(l10n.editNameTitle),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: InputDecoration(labelText: l10n.fullNameLabel),
              validator: (v) => (v == null || v.trim().isEmpty) ? l10n.requiredValidatorError : null,
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
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(l10n.saveChangesButton),
        ),
      ],
    );
  }
}
