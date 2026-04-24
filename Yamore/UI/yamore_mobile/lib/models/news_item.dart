class NewsItemModel {
  final int newsId;
  final String title;
  final String text;
  final String? imageUrl;
  final DateTime? createdAt;

  NewsItemModel({
    required this.newsId,
    required this.title,
    required this.text,
    this.imageUrl,
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
      createdAt = DateTime.tryParse(createdRaw);
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    }

    return NewsItemModel(
      newsId: _key(json, 'newsId', 'NewsId') as int,
      title: (_key(json, 'title', 'Title') as String?) ?? '',
      text: (_key(json, 'text', 'Text') as String?) ?? '',
      imageUrl: _key(json, 'imageUrl', 'ImageUrl') as String?,
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
