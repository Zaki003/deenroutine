class DailyQuote {
  final String quoteId;
  final String text;
  final String source;
  final String category;

  DailyQuote({
    required this.quoteId,
    required this.text,
    required this.source,
    required this.category,
  });

  factory DailyQuote.fromMap(String id, Map<String, dynamic> map) => DailyQuote(
        quoteId: id,
        text: map['text'] ?? '',
        source: map['source'] ?? '',
        category: map['category'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'text': text,
        'source': source,
        'category': category,
      };
}
