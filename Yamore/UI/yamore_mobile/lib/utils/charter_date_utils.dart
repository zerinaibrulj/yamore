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
  ///
  /// Treats offset-less ISO strings as UTC (ASP.NET may omit `Z`) so the
  /// calendar day does not shift again on read.
  static DateTime fromApi(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw FormatException('Empty date');
    }

    final DateTime utc;
    if (trimmed.endsWith('Z')) {
      utc = DateTime.parse(trimmed).toUtc();
    } else if (RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed)) {
      utc = DateTime.parse(trimmed).toUtc();
    } else if (trimmed.contains('T')) {
      final asUtc = DateTime.tryParse('${trimmed}Z');
      utc = (asUtc ?? DateTime.parse(trimmed)).toUtc();
    } else {
      final d = DateTime.parse(trimmed);
      utc = DateTime.utc(d.year, d.month, d.day, 12, 0, 0);
    }

    return DateTime(utc.year, utc.month, utc.day);
  }
}
