class NewsItemModel {
  final int newsId;
  final String title;
  final String text;
  final DateTime? createdAt;

  NewsItemModel({
    required this.newsId,
    required this.title,
    required this.text,
    this.createdAt,
  });

  static dynamic _key(
    Map<String, dynamic> json,
    String camel,
    String pascal,
  ) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory NewsItemModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = _key(json, 'createdAt', 'CreatedAt');
    DateTime? createdAt;
    if (createdRaw is String && createdRaw.trim().isNotEmpty) {
      // Match notifications: .NET often omits "Z" for UTC; treat offset-less ISO as UTC.
      createdAt = _parseApiDateTime(createdRaw);
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    }

    return NewsItemModel(
      newsId: _key(json, 'newsId', 'NewsId') as int,
      title: (_key(json, 'title', 'Title') as String?) ?? '',
      text: (_key(json, 'text', 'Text') as String?) ?? '',
      createdAt: createdAt,
    );
  }
}

class PagedNewsItems {
  final int? count;
  final List<NewsItemModel> resultList;

  PagedNewsItems({this.count, required this.resultList});

  static dynamic _key(
    Map<String, dynamic> json,
    String camel,
    String pascal,
  ) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory PagedNewsItems.fromJson(Map<String, dynamic> json) {
    final rawList = _key(json, 'resultList', 'ResultList');
    final list = rawList is List<dynamic> ? rawList : <dynamic>[];
    return PagedNewsItems(
      count: _key(json, 'count', 'Count') as int?,
      resultList: list
          .map((e) => NewsItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

DateTime? newsDisplayTime(DateTime? t) {
  if (t == null) return null;
  return t.isUtc ? t.toLocal() : t;
}

/// If the server sends an ISO-8601 instant without a timezone, treat it as UTC
/// (same as [NotificationModel] parsing) so local display matches the real time.
DateTime? _parseApiDateTime(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.endsWith('Z')) return DateTime.tryParse(t);
  if (RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(t)) {
    return DateTime.tryParse(t);
  }
  if (t.contains('T') && t.length > 10) {
    return DateTime.tryParse('${t}Z') ?? DateTime.tryParse(t);
  }
  return DateTime.tryParse(t);
}
