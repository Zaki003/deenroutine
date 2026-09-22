import 'dart:math';

import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Invites someone else to try DeenRoutine via the OS share sheet - either
/// nudged once at a positive moment ([shouldShowPrompt]/[markPromptShown])
/// or anytime from Settings, which calls [share] directly with no gating.
///
/// Deliberately a different trigger moment than [ReviewPromptService]'s
/// (quiz score / 7-day streak) - see DashboardScreen's milestone handling -
/// so the two asks never compete for the same moment.
class SharePromptService {
  static const _prefsKey = 'share_prompt_shown';
  static const _storeLink =
      'https://play.google.com/store/apps/details?id=com.ZakiFaiaz.deenroutine';

  /// Whether the contextual nudge should still be offered. Capped to once
  /// ever, same reasoning as [ReviewPromptService] - asking again regardless
  /// of how the user responded last time would just be naggy.
  Future<bool> shouldShowPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefsKey) ?? false);
  }

  /// Marks the contextual nudge as used - shared or dismissed both count,
  /// so it never shows a second time.
  Future<void> markPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, true);
  }

  /// Opens the OS share sheet with an invite message, picked at random.
  /// [streakDays] unlocks the streak-flavoured message alongside the
  /// general one - never fabricated, so a call with no real streak to cite
  /// (Settings' always-available row) sticks to the general message.
  Future<void> share({int? streakDays}) {
    final messages = [
      "I've genuinely started sticking with my prayers and habits since I "
          'started using DeenRoutine - not an exaggeration. Thought you\'d '
          'like it too: $_storeLink',
      if (streakDays != null)
        '$streakDays days into my streak on DeenRoutine and honestly proud '
            "of it. Small, consistent steps - that's the whole trick. "
            "You'd be good at this: $_storeLink",
    ];
    final message = messages[Random().nextInt(messages.length)];
    return SharePlus.instance.share(ShareParams(text: message));
  }
}
