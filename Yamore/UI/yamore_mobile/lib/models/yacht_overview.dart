import 'yacht_detail.dart';

class YachtOverview {
  final int yachtId;
  final String name;
  final String? locationName;
  final String? countryName;
  final String? ownerName;
  final int? ownerId;
  final int? yearBuilt;
  final double? length;
  final int capacity;
  final double pricePerDay;
  final String? stateMachine;
  final int? thumbnailImageId;
  final int categoryId;
  final double? averageRating;
  final int reviewCount;

  YachtOverview({
    required this.yachtId,
    required this.name,
    this.locationName,
    this.countryName,
    this.ownerName,
    this.ownerId,
    this.yearBuilt,
    this.length,
    required this.capacity,
    required this.pricePerDay,
    this.stateMachine,
    this.thumbnailImageId,
    required this.categoryId,
    this.averageRating,
    this.reviewCount = 0,
  });

  /// From full yacht detail when the overview list omits this yacht (pagination or filters).
  factory YachtOverview.fromYachtDetail(YachtDetail d) {
    final id = d.yachtId;
    if (id == null) {
      throw ArgumentError('yachtId is required');
    }
    return YachtOverview(
      yachtId: id,
      name: d.name,
      capacity: d.capacity,
      pricePerDay: d.pricePerDay,
      categoryId: d.categoryId,
      yearBuilt: d.yearBuilt > 0 ? d.yearBuilt : null,
      length: d.length > 0 ? d.length : null,
      ownerId: d.ownerId,
    );
  }

  factory YachtOverview.fromJson(Map<String, dynamic> json) {
    return YachtOverview(
      yachtId: json['yachtId'] as int,
      name: json['name'] as String? ?? '',
      locationName: json['locationName'] as String?,
      countryName: json['countryName'] as String? ?? json['CountryName'] as String?,
      ownerName: json['ownerName'] as String?,
      ownerId: json['ownerId'] as int?,
      yearBuilt: json['yearBuilt'] as int?,
      length: (json['length'] as num?)?.toDouble(),
      capacity: json['capacity'] as int? ?? 0,
      pricePerDay: (json['pricePerDay'] as num?)?.toDouble() ?? 0,
      stateMachine: json['stateMachine'] as String? ?? json['StateMachine'] as String?,
      thumbnailImageId: json['thumbnailImageId'] as int?,
      categoryId: json['categoryId'] as int? ?? 0,
      averageRating: (json['averageRating'] ?? json['AverageRating']) == null
          ? null
          : (json['averageRating'] ?? json['AverageRating'] as num).toDouble(),
      reviewCount:
          (json['reviewCount'] ?? json['ReviewCount']) as int? ?? 0,
    );
  }
}

class PagedYachtOverview {
  final int? count;
  final List<YachtOverview> resultList;

  PagedYachtOverview({this.count, required this.resultList});

  factory PagedYachtOverview.fromJson(Map<String, dynamic> json) {
    final list = json['resultList'] as List<dynamic>? ?? [];
    return PagedYachtOverview(
      count: json['count'] as int?,
      resultList: list
          .map((e) => YachtOverview.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
