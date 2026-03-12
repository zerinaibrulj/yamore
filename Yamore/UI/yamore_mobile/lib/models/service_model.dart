class ServiceModel {
  final int serviceId;
  final String name;
  final String? description;
  final double? price;
  final int? serviceCategoryId;

  ServiceModel({
    required this.serviceId,
    required this.name,
    this.description,
    this.price,
    this.serviceCategoryId,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'] as int,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      serviceCategoryId: json['serviceCategoryId'] as int?,
    );
  }
}

class PagedServices {
  final int? count;
  final List<ServiceModel> resultList;

  PagedServices({this.count, required this.resultList});

  static dynamic _key(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory PagedServices.fromJson(Map<String, dynamic> json) {
    final rawList = _key(json, 'resultList', 'ResultList');
    final list = rawList is List<dynamic> ? rawList : <dynamic>[];
    return PagedServices(
      count: _key(json, 'count', 'Count') as int?,
      resultList: list
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
