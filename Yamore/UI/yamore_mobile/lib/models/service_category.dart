class ServiceCategory {
  final int serviceCategoryId;
  final String name;
  final String? description;

  ServiceCategory({
    required this.serviceCategoryId,
    required this.name,
    this.description,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      serviceCategoryId: json['serviceCategoryId'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
    );
  }
}

class PagedServiceCategories {
  final int? count;
  final List<ServiceCategory> resultList;

  PagedServiceCategories({this.count, required this.resultList});

  static dynamic _key(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory PagedServiceCategories.fromJson(Map<String, dynamic> json) {
    final rawList = _key(json, 'resultList', 'ResultList');
    final list = rawList is List<dynamic> ? rawList : <dynamic>[];
    return PagedServiceCategories(
      count: _key(json, 'count', 'Count') as int?,
      resultList: list
          .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
