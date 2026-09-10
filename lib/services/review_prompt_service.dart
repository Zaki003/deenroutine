import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asks the OS to show its native in-app review sheet (Play/App Store),
/// right after a moment the user is likely feeling good about the app - a
/// high quiz score or a 7-day habit streak. Both platforms already throttle
/// how often the dialog can actually appear regardless of how often this is
/// called, but asking more than once per install would still be needlessly
/// naggy on our side, so [_prefsKey] caps it to once ever, whichever
/// trigger fires first.
class ReviewPromptService {
  static const _prefsKey = 'review_prompt_shown';

  Future<void> maybeRequestReview() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefsKey) ?? false) return;
    await prefs.setBool(_prefsKey, true);

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }
}
