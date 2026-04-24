/// Puts a **dot** between every group of three digits in the integer part (e.g. 118550 → `118.550`).
/// Used for amounts of **1.000** and up; smaller whole amounts stay as-is (e.g. `€500`).
String _intPartWithDotThousands(int n) {
  if (n < 0) {
    return '-${_intPartWithDotThousands(-n)}';
  }
  final s = n.toString();
  if (s.length <= 3) {
    return s;
  }
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) {
      buf.write('.');
    }
    buf.write(s[i]);
  }
  return buf.toString();
}

/// Euro amounts for the admin dashboard. Whole euros use **dot thousands** when the amount
/// is 1.000+ (e.g. `€118.550`). If there are cents, the **decimal** separator is a **comma** so
/// it is not confused with the thousands dot (e.g. `€1.234,56`).
String formatEuroDashboard(double value) {
  if (value.isNaN) {
    return '€0';
  }
  final sign = value < 0;
  var v = sign ? -value : value;
  if (v.isInfinite) {
    return '€0';
  }
  final rounded = (v * 100).round() / 100.0;
  if (rounded == rounded.truncateToDouble()) {
    return '${sign ? '-' : ''}€${_intPartWithDotThousands(rounded.toInt())}';
  }
  final intPart = rounded.truncate();
  final fracHundredths = ((rounded - intPart) * 100).round().abs() % 100;
  return '${sign ? '-' : ''}€${_intPartWithDotThousands(intPart)},'
      '${fracHundredths.toString().padLeft(2, '0')}';
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
