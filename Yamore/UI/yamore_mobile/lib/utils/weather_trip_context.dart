import '../models/weather_forecast.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Forecast rows whose [WeatherForecastModel.forecastDate] falls on a calendar day
/// between [tripStart] and [tripEnd] (inclusive). Sorted by date ascending.
List<WeatherForecastModel> forecastsInTripRange(
  Iterable<WeatherForecastModel> items,
  DateTime tripStart,
  DateTime tripEnd,
) {
  var low = _dateOnly(tripStart);
  var high = _dateOnly(tripEnd);
  if (high.isBefore(low)) {
    final t = low;
    low = high;
    high = t;
  }
  final list = items.where((f) {
    if (f.forecastDate == null) return false;
    final d = _dateOnly(f.forecastDate!);
    return !d.isBefore(low) && !d.isAfter(high);
  }).toList();
  list.sort(
    (a, b) => a.forecastDate!.compareTo(b.forecastDate!),
  );
  return list;
}

/// Closest forecast by absolute time difference to [tripStart] (ignores null dates).
WeatherForecastModel? nearestForecastToTripStart(
  Iterable<WeatherForecastModel> items,
  DateTime tripStart,
) {
  WeatherForecastModel? best;
  Duration bestDiff = const Duration(days: 999999);
  for (final f in items) {
    if (f.forecastDate == null) continue;
    final diff = f.forecastDate!.difference(tripStart).abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = f;
    }
  }
  return best;
}

String formatTripDateRange(DateTime start, DateTime end) {
  String p(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  final ds = p(start);
  final de = p(end);
  if (ds == de) return ds;
  return '$ds – $de';
}

String formatForecastDateTime(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.'
    '${d.month.toString().padLeft(2, '0')}.'
    '${d.year} '
    '${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';
