/// Charter bookings use calendar dates (no timezone shift on the day).
///
/// Never call [DateTime.toUtc] on a local midnight picked in the UI — that
/// moves the calendar day backward in UTC+ zones and saves the wrong date.
class CharterDateUtils {
  CharterDateUtils._();

  /// Local calendar day at midnight (no time-zone conversion).
  static DateTime localDateOnly(DateTime value) {
    final local = value.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  /// Encodes the user's selected calendar day for the API (noon UTC on that Y-M-D).
  static String toApiJson(DateTime localCalendarDay) {
    final d = localDateOnly(localCalendarDay);
    return DateTime.utc(d.year, d.month, d.day, 12, 0, 0).toIso8601String();
  }

  /// Decodes API reservation/charter dates for display and pickers.
  static DateTime fromApi(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Empty date');
    }
    final parsed = DateTime.parse(trimmed);
    final utc = parsed.isUtc ? parsed : parsed.toUtc();
    return DateTime(utc.year, utc.month, utc.day);
  }
}
