/// Day 0 of the daily-quote rotation. Shared by the dashboard's lookup and the
/// daily-quote notification scheduler so both always pick the same quote.
final DateTime quoteEpoch = DateTime.utc(2026, 1, 1);

/// Index into a quote bank of [total] for the moment [instant].
///
/// The day number is counted in UTC: a local date would hand users in Sydney
/// and Los Angeles different quotes at the same moment. Dart's % is never
/// negative, so instants before the epoch still map into range.
int quoteDayIndex(DateTime instant, int total) {
  final utc = instant.toUtc();
  final dayNumber =
      DateTime.utc(utc.year, utc.month, utc.day).difference(quoteEpoch).inDays;
  return dayNumber % total;
}

/// The next [count] local times at [hour]:[minute], starting with today's if
/// it hasn't passed yet and tomorrow's otherwise.
List<DateTime> upcomingDailyTimes(
  DateTime now, {
  required int hour,
  required int minute,
  required int count,
}) {
  final todayAtTime = DateTime(now.year, now.month, now.day, hour, minute);
  final firstOffset = todayAtTime.isAfter(now) ? 0 : 1;
  return [
    for (var i = 0; i < count; i++)
      DateTime(now.year, now.month, now.day + firstOffset + i, hour, minute),
  ];
}
