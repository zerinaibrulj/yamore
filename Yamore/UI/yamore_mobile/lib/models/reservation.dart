class Reservation {
  final int reservationId;
  final int userId;
  final int yachtId;
  final DateTime startDate;
  final DateTime endDate;
  final double? totalPrice;
  final String? status;
  final DateTime? createdAt;
  final bool isPaid;

  Reservation({
    required this.reservationId,
    required this.userId,
    required this.yachtId,
    required this.startDate,
    required this.endDate,
    this.totalPrice,
    this.status,
    this.createdAt,
    this.isPaid = false,
  });

  int get durationDays {
    return endDate.difference(startDate).inDays;
  }

  /// Case-insensitive key lookup so status is read correctly regardless of API serialization.
  static dynamic _v(Map<String, dynamic> json, String name) {
    final lower = name.toLowerCase();
    for (final k in json.keys) {
      if (k.toLowerCase() == lower) return json[k];
    }
    return null;
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    final statusRaw = _v(json, 'status');
    final paidRaw = _v(json, 'isPaid');
    final isPaid = paidRaw is bool
        ? paidRaw
        : (paidRaw is int ? paidRaw != 0 : (paidRaw?.toString() == 'true'));
    return Reservation(
      reservationId: _v(json, 'reservationId') as int,
      userId: _v(json, 'userId') as int,
      yachtId: _v(json, 'yachtId') as int,
      startDate: DateTime.parse(_v(json, 'startDate') as String),
      endDate: DateTime.parse(_v(json, 'endDate') as String),
      totalPrice: (_v(json, 'totalPrice') as num?)?.toDouble(),
      status: statusRaw is String ? statusRaw : statusRaw?.toString(),
      createdAt: _v(json, 'createdAt') != null
          ? DateTime.tryParse(_v(json, 'createdAt').toString())
          : null,
      isPaid: isPaid,
    );
  }
}

/// Result of [ApiService.cancelReservation] (reservation + whether a card payment was on file).
class CancelReservationResult {
  const CancelReservationResult({
    required this.reservation,
    this.hadCardPayment = false,
  });

  final Reservation reservation;
  final bool hadCardPayment;
}

class PagedReservations {
  final int? count;
  final List<Reservation> resultList;

  PagedReservations({this.count, required this.resultList});

  static dynamic _v(Map<String, dynamic> json, String name) {
    final lower = name.toLowerCase();
    for (final k in json.keys) {
      if (k.toLowerCase() == lower) return json[k];
    }
    return null;
  }

  factory PagedReservations.fromJson(Map<String, dynamic> json) {
    final rawList = _v(json, 'resultList') ?? _v(json, 'ResultList');
    final list = rawList is List<dynamic> ? rawList : <dynamic>[];
    final countRaw = _v(json, 'count') ?? _v(json, 'Count');
    return PagedReservations(
      count: countRaw as int?,
      resultList: list
          .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
