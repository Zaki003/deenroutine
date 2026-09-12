import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/daily_quote.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/deen_colors.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/quote_card.dart';

/// Up to [AuthProvider.maxFreeFavorites] ayats/hadiths saved from the daily
/// quote card. There's no browse-all-quotes screen yet, so this only ever
/// shrinks from here (unfavoriting) - the one way in is the heart on
/// whichever quote is showing as today's on the dashboard.
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _firestoreService = FirestoreService();
  // null while loading, distinct from an empty (but loaded) list.
  List<DailyQuote>? _quotes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ids = context.read<AuthProvider>().favoriteQuoteIds;
    final quotes = await _firestoreService.getQuotesByIds(ids);
    // Firestore's whereIn doesn't preserve input order - restore
    // most-recently-favourited-first so the list doesn't reshuffle each load.
    final byId = {for (final q in quotes) q.quoteId: q};
    final ordered = ids.reversed.map((id) => byId[id]).whereType<DailyQuote>().toList();
    if (mounted) setState(() => _quotes = ordered);
  }

  Future<void> _handleRemove(DailyQuote quote) async {
    await context.read<AuthProvider>().toggleFavorite(quote.quoteId);
    // Only reachable as a removal here (this screen has no way to add a
    // quote that isn't already favourited), so just drop it locally instead
    // of re-fetching the whole list from Firestore.
    if (mounted) {
      setState(() => _quotes = _quotes?.where((q) => q.quoteId != quote.quoteId).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final isBangla = context.watch<LocaleProvider>().isBangla;
    final quotes = _quotes;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.favoritesTitle)),
      body: quotes == null
          ? const Center(child: CircularProgressIndicator(color: DeenColors.primary))
          : quotes.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: EmptyStateCard(
                      icon: Icons.favorite_border_rounded,
                      title: l10n.favoritesTitle,
                      message: l10n.favoritesEmptyBody,
                      dark: dark,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: quotes.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Text(
                        l10n.favoritesCountLabel(quotes.length, AuthProvider.maxFreeFavorites),
                        style: TextStyle(fontSize: 12, color: DeenColors.textMuted(dark)),
                      );
                    }
                    final quote = quotes[index - 1];
                    return QuoteCard(
                      quote: quote,
                      isBangla: isBangla,
                      dark: dark,
                      isFavorite: true,
                      onToggleFavorite: () => _handleRemove(quote),
                    );
                  },
                ),
    );
  }
}
