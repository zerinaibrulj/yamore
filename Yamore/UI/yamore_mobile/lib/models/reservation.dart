class Reservation {
  final int reservationId;
  final int userId;
  final int yachtId;
  final DateTime startDate;
  final DateTime endDate;
  final double? totalPrice;
  final String? status;
  final DateTime? createdAt;

  Reservation({
    required this.reservationId,
    required this.userId,
    required this.yachtId,
    required this.startDate,
    required this.endDate,
    this.totalPrice,
    this.status,
    this.createdAt,
  });

  int get durationDays {
    return endDate.difference(startDate).inDays;
  }

  /// Reads a value from json with camelCase or PascalCase key (API may use either).
  static dynamic _key(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reservationId: (_key(json, 'reservationId', 'ReservationId')) as int,
      userId: (_key(json, 'userId', 'UserId')) as int,
      yachtId: (_key(json, 'yachtId', 'YachtId')) as int,
      startDate: DateTime.parse((_key(json, 'startDate', 'StartDate')) as String),
      endDate: DateTime.parse((_key(json, 'endDate', 'EndDate')) as String),
      totalPrice: (_key(json, 'totalPrice', 'TotalPrice') as num?)?.toDouble(),
      status: _key(json, 'status', 'Status') as String?,
      createdAt: _key(json, 'createdAt', 'CreatedAt') != null
          ? DateTime.tryParse((_key(json, 'createdAt', 'CreatedAt')) as String)
          : null,
    );
  }
}

class PagedReservations {
  final int? count;
  final List<Reservation> resultList;

  PagedReservations({this.count, required this.resultList});

  static dynamic _key(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory PagedReservations.fromJson(Map<String, dynamic> json) {
    final rawList = _key(json, 'resultList', 'ResultList');
    final list = rawList is List<dynamic> ? rawList : <dynamic>[];
    return PagedReservations(
      count: _key(json, 'count', 'Count') as int?,
      resultList: list
          .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
