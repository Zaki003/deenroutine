import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/text_format.dart';
import '../../widgets/onboarding_scaffold.dart';
import 'onboarding_location_screen.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = capitalizeWords(context.watch<AuthProvider>().appUser?.name ?? '');

    return OnboardingScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OnboardingStaggerIn(
                    index: 0,
                    child: Column(
                      children: [
                        const Icon(Icons.mosque, size: 48, color: DeenColors.gold),
                        const SizedBox(height: 10),
                        Text(
                          l10n.appTitle,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: DeenColors.primaryText(dark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  OnboardingStaggerIn(
                    index: 1,
                    child: Text(
                      l10n.onboardingTagline,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: DeenColors.textMuted(dark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  OnboardingStaggerIn(
                    index: 2,
                    child: Column(
                      children: [
                        Text(
                          l10n.assalamuAlaikumGreeting,
                          style: const TextStyle(fontSize: 12, color: DeenColors.gold, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: DeenColors.primaryText(dark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  OnboardingStaggerIn(
                    index: 3,
                    child: Text(
                      l10n.onboardingWelcomeSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: DeenColors.textMuted(dark)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const OnboardingLocationScreen())),
            child: Text(l10n.onboardingGetStartedButton),
          ),
        ],
      ),
    );
  }
}
