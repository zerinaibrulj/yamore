/// Euro amounts for the admin dashboard: the **decimal separator is always a dot** (e.g. `1234.56`).
/// Whole euro amounts are shown without decimals (e.g. `€138050`), matching the reference cards.
String formatEuroDashboard(double value) {
  final rounded = (value * 100).round() / 100;
  if (rounded == rounded.truncateToDouble()) {
    return '€${rounded.toInt()}';
  }
  return '€${rounded.toStringAsFixed(2)}';
}

/// Y-axis on revenue chart: e.g. `€129.8k` (dot in the k value from `toStringAsFixed(1)`).
String formatEuroCompactAxis(double value) {
  if (value >= 1000) {
    final k = value / 1000;
    if (k == k.roundToDouble()) {
      return '€${k.toInt()}k';
    }
    return '€${k.toStringAsFixed(1)}k';
  }
  return value >= 1 ? '€${value.toStringAsFixed(0)}' : '€0';
}
