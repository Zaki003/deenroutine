import '../l10n/app_localizations.dart';

/// Localizes a Learn topic's raw category key (e.g. `'Salah'`, matching
/// `QuizQuestion.category` and [LearnProvider.kTopicOrder]) into its
/// display name. Falls back to the raw key for anything unrecognized.
String learnTopicLabel(AppLocalizations l10n, String category) {
  switch (category) {
    case 'Belief':
      return l10n.learnTopicBelief;
    case 'Pillars':
      return l10n.learnTopicPillars;
    case 'Salah':
      return l10n.learnTopicSalah;
    case 'Quran':
      return l10n.learnTopicQuran;
    case 'Seerah':
      return l10n.learnTopicSeerah;
    case 'Prophets':
      return l10n.learnTopicProphets;
    case 'History':
      return l10n.learnTopicHistory;
    case 'Ramadan':
      return l10n.learnTopicRamadan;
    case 'Hajj':
      return l10n.learnTopicHajj;
    case 'Manners':
      return l10n.learnTopicManners;
    default:
      return category;
  }
}
