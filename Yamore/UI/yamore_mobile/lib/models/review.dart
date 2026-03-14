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

  static dynamic _key(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory Review.fromJson(Map<String, dynamic> json) {
    final ownerResp = _key(json, 'ownerResponse', 'OwnerResponse') as String?;
    final ownerRespDate = _key(json, 'ownerResponseDate', 'OwnerResponseDate');
    return Review(
      reviewId: (_key(json, 'reviewId', 'ReviewId') as num?)?.toInt() ?? 0,
      reservationId: (_key(json, 'reservationId', 'ReservationId') as num?)?.toInt() ?? 0,
      userId: (_key(json, 'userId', 'UserId') as num?)?.toInt() ?? 0,
      yachtId: (_key(json, 'yachtId', 'YachtId') as num?)?.toInt() ?? 0,
      rating: (_key(json, 'rating', 'Rating') as num?)?.toInt(),
      comment: _key(json, 'comment', 'Comment') as String?,
      datePosted: _key(json, 'datePosted', 'DatePosted') != null
          ? DateTime.tryParse(_key(json, 'datePosted', 'DatePosted').toString())
          : null,
      ownerResponse: ownerResp,
      ownerResponseDate: ownerRespDate != null
          ? DateTime.tryParse(ownerRespDate.toString())
          : null,
      isReported: _key(json, 'isReported', 'IsReported') as bool? ?? false,
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
