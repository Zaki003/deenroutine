import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/habit.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../theme/deen_colors.dart';
import '../../utils/text_format.dart';
import '../../widgets/account_row.dart';
import '../../widgets/avatar_graphic.dart';
import '../../widgets/avatar_picker_dialog.dart';
import '../../widgets/deen_card.dart';
import '../../widgets/edit_name_dialog.dart';
import 'favorites_screen.dart';
import 'habit_insights_section.dart';
import 'prayer_stats_section.dart';
import 'settings_screen.dart';

/// FR-03: Profile — identity, favorites, and the Habit and Prayer insights.
/// Settings (theme, language, prayer method, account actions) live one tap
/// away via the gear icon, in [SettingsScreen].
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final habits = context.watch<HabitProvider>().habits;
    final user = auth.appUser;
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final name = capitalizeWords(user?.name ?? '');
    // A one-off to-do has no week of recurrence to summarize - excluded the
    // same way the Habits tab and Dashboard already exclude it from
    // streak/week displays.
    final recurringHabits =
        habits.where((h) => h.frequency != HabitFrequency.once).toList();

    return ColoredBox(
      color: DeenColors.surface(dark),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.navProfile,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DeenColors.primaryText(dark),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                color: DeenColors.primaryText(dark),
                tooltip: l10n.settingsTitle,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(23),
                onTap: () => showDialog(context: context, builder: (_) => const AvatarPickerDialog()),
                child: AvatarGraphic(
                  avatar: user?.avatar,
                  initial: (name.isNotEmpty ? name[0] : '?').toUpperCase(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => EditNameDialog(currentName: name),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: DeenColors.primaryText(dark),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.edit_outlined, size: 14, color: DeenColors.textMuted(dark)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(fontSize: 11.5, color: DeenColors.textMuted(dark)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DeenCard(
            dark: dark,
            margin: const EdgeInsets.only(bottom: 20),
            child: AccountRow(
              icon: Icons.favorite_border_rounded,
              label: l10n.favoritesTitle,
              dark: dark,
              trailingText: l10n.favoritesCountLabel(
                auth.appUser?.favoriteQuoteIds.length ?? 0,
                AuthProvider.maxFreeFavorites,
              ),
              showChevron: true,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              ),
            ),
          ),
          if (recurringHabits.isNotEmpty) const HabitInsightsSection(),
          const PrayerStatsSection(),
        ],
      ),
    );
  }
}
