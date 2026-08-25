/// Formats a countdown as `'2h 14m'` (or `'14m'` under an hour, `'<1m'`
/// once it's down to seconds), used for the next-prayer hero cards.
String formatCountdown(Duration d) {
  if (d.isNegative) return '0m';
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m';
  if (minutes > 0) return '${minutes}m';
  return '<1m';
}

/// Formats a duration as `m:ss` (e.g. `'3:12'`), used by the timer habit
/// control where seconds-level precision matters — [formatCountdown] is
/// too coarse (drops seconds entirely) for that.
String formatMmSs(Duration d) {
  final clamped = d.isNegative ? Duration.zero : d;
  final minutes = clamped.inMinutes;
  final seconds = clamped.inSeconds.remainder(60);
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
