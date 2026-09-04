import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../theme/deen_colors.dart';
import 'avatar_graphic.dart';

/// Tap an option to pick it — saves immediately, no separate confirm step,
/// matching the Appearance picker's Light/Dark/System interaction.
class AvatarPickerDialog extends StatefulWidget {
  const AvatarPickerDialog({super.key});

  @override
  State<AvatarPickerDialog> createState() => _AvatarPickerDialogState();
}

class _AvatarPickerDialogState extends State<AvatarPickerDialog> {
  bool _submitting = false;

  Future<void> _pick(AvatarOption option) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final ok = await context.read<AuthProvider>().updateProfile(avatar: option);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.chooseAvatarTitle),
      content: _submitting
          ? const SizedBox(
              height: 96,
              child: Center(child: CircularProgressIndicator()),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AvatarChoice(
                  avatar: AvatarOption.male,
                  label: l10n.avatarMaleLabel,
                  onTap: () => _pick(AvatarOption.male),
                ),
                const SizedBox(width: 28),
                _AvatarChoice(
                  avatar: AvatarOption.femaleHijab,
                  label: l10n.avatarFemaleLabel,
                  onTap: () => _pick(AvatarOption.femaleHijab),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
      ],
    );
  }
}

class _AvatarChoice extends StatelessWidget {
  final AvatarOption avatar;
  final String label;
  final VoidCallback onTap;

  const _AvatarChoice({required this.avatar, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AvatarGraphic(avatar: avatar, initial: '', radius: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12.5, color: DeenColors.primaryText(dark))),
          ],
        ),
      ),
    );
  }
}
