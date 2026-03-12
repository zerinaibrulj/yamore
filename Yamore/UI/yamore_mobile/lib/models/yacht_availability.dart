class YachtAvailability {
  final int yachtAvailabilityId;
  final int yachtId;
  final DateTime startDate;
  final DateTime endDate;
  final bool isBlocked;
  final String? note;

  YachtAvailability({
    required this.yachtAvailabilityId,
    required this.yachtId,
    required this.startDate,
    required this.endDate,
    required this.isBlocked,
    this.note,
  });

  factory YachtAvailability.fromJson(Map<String, dynamic> json) {
    return YachtAvailability(
      yachtAvailabilityId: json['yachtAvailabilityId'] as int,
      yachtId: json['yachtId'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isBlocked: json['isBlocked'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}

class PagedYachtAvailabilities {
  final int? count;
  final List<YachtAvailability> resultList;

  PagedYachtAvailabilities({this.count, required this.resultList});

  static dynamic _key(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory PagedYachtAvailabilities.fromJson(Map<String, dynamic> json) {
    final rawList = _key(json, 'resultList', 'ResultList');
    final list = rawList is List<dynamic> ? rawList : <dynamic>[];
    return PagedYachtAvailabilities(
      count: _key(json, 'count', 'Count') as int?,
      resultList: list
          .map((e) => YachtAvailability.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
