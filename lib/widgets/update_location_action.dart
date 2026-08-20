import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/prayer_provider.dart';
import '../utils/prayer_error_messages.dart';

/// Shared "update location" confirm dialog + result snackbar, triggered
/// from the small location icon on [GradientHeroCard]. Kept in one place
/// since both the Dashboard and Prayer screen wire it up identically.
Future<void> confirmUpdateLocation(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.updateLocationTitle),
      content: Text(l10n.updateLocationBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.cancelButton),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.updateLocationConfirm),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final provider = context.read<PrayerProvider>();
  final success = await provider.updateLocation();
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        success
            ? l10n.updateLocationSuccess
            : prayerErrorMessage(l10n, provider.errorType!, provider.errorDetail),
      ),
    ),
  );
}
