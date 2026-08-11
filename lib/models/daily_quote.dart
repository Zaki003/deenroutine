class DailyQuote {
  final String quoteId;
  final String text;
  final String source;
  final String category;

  /// Bangla translation of [text]. Empty until Bangla content is added to
  /// the `DailyQuotes` collection — [displayText] falls back to [text]
  /// until then.
  final String textBn;

  DailyQuote({
    required this.quoteId,
    required this.text,
    required this.source,
    required this.category,
    this.textBn = '',
  });

  /// [text] in the requested language, falling back to English when no
  /// Bangla translation has been added to Firestore yet.
  String displayText(bool bangla) => (bangla && textBn.isNotEmpty) ? textBn : text;

  factory DailyQuote.fromMap(String id, Map<String, dynamic> map) => DailyQuote(
        quoteId: id,
        text: map['text'] ?? '',
        source: map['source'] ?? '',
        category: map['category'] ?? '',
        textBn: map['textBn'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'text': text,
        'source': source,
        'category': category,
        'textBn': textBn,
      };
}
