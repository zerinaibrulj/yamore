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

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reservationId: json['reservationId'] as int,
      userId: json['userId'] as int,
      yachtId: json['yachtId'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      totalPrice: (json['totalPrice'] as num?)?.toDouble(),
      status: json['status'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
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
