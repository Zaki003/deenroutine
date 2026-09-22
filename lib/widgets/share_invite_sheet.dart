import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/analytics_service.dart';
import '../services/share_prompt_service.dart';
import '../theme/deen_colors.dart';
import 'deen_card.dart';

/// The contextual "share DeenRoutine" nudge - see [SharePromptService] for
/// the once-ever gating this assumes the caller already checked.
Future<void> showShareInviteSheet(BuildContext context, {required int streakDays}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _ShareInviteSheet(streakDays: streakDays),
  );
}

class _ShareInviteSheet extends StatelessWidget {
  final int streakDays;

  const _ShareInviteSheet({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DeenCard(
          dark: dark,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DeenColors.goldSoft.withValues(alpha: 0.3),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, size: 18, color: DeenColors.gold),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.shareInviteTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: DeenColors.primaryText(dark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l10n.shareInviteBody,
                style: TextStyle(fontSize: 13, height: 1.4, color: DeenColors.textMuted(dark)),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.ios_share_rounded, size: 16),
                      label: Text(l10n.shareInviteButton),
                      onPressed: () {
                        AnalyticsService().logShareTapped(source: 'streak_milestone');
                        SharePromptService().share(streakDays: streakDays);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.notNowButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
