class Review {
  final int reviewId;
  final int reservationId;
  final int userId;
  final int yachtId;
  final int? rating;
  final String? comment;
  final DateTime? datePosted;
  final String? ownerResponse;
  final DateTime? ownerResponseDate;
  final bool isReported;

  Review({
    required this.reviewId,
    required this.reservationId,
    required this.userId,
    required this.yachtId,
    this.rating,
    this.comment,
    this.datePosted,
    this.ownerResponse,
    this.ownerResponseDate,
    this.isReported = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      reviewId: json['reviewId'] as int,
      reservationId: json['reservationId'] as int,
      userId: json['userId'] as int,
      yachtId: json['yachtId'] as int,
      rating: json['rating'] as int?,
      comment: json['comment'] as String?,
      datePosted: json['datePosted'] != null
          ? DateTime.tryParse(json['datePosted'] as String)
          : null,
      ownerResponse: json['ownerResponse'] as String?,
      ownerResponseDate: json['ownerResponseDate'] != null
          ? DateTime.tryParse(json['ownerResponseDate'] as String)
          : null,
      isReported: json['isReported'] as bool? ?? false,
    );
  }
}

class PagedReviews {
  final int? count;
  final List<Review> resultList;

  PagedReviews({this.count, required this.resultList});

  static dynamic _key(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory PagedReviews.fromJson(Map<String, dynamic> json) {
    final rawList = _key(json, 'resultList', 'ResultList');
    final list = rawList is List<dynamic> ? rawList : <dynamic>[];
    return PagedReviews(
      count: _key(json, 'count', 'Count') as int?,
      resultList:
          list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
