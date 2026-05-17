class YachtCalendarBlock {
  final DateTime startDate;
  final DateTime endDate;
  final String kind;

  YachtCalendarBlock({
    required this.startDate,
    required this.endDate,
    required this.kind,
  });

  static dynamic _v(Map<String, dynamic> json, String name) {
    final lower = name.toLowerCase();
    for (final k in json.keys) {
      if (k.toLowerCase() == lower) return json[k];
    }
    return null;
  }

  static DateTime _parseDate(dynamic raw) {
    final t = raw.toString().trim();
    if (t.endsWith('Z')) {
      return DateTime.parse(t).toUtc();
    }
    if (RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(t)) {
      return DateTime.parse(t).toUtc();
    }
    if (t.contains('T')) {
      final withZ = DateTime.tryParse('${t}Z');
      if (withZ != null) return withZ.toUtc();
    }
    final parsed = DateTime.parse(t);
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }

  factory YachtCalendarBlock.fromJson(Map<String, dynamic> json) {
    return YachtCalendarBlock(
      startDate: _parseDate(_v(json, 'startDate')),
      endDate: _parseDate(_v(json, 'endDate')),
      kind: _v(json, 'kind')?.toString() ?? 'reservation',
    );
  }
}
