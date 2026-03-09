class StatisticsDtoModel {
  final int totalBookings;
  final double totalRevenue;
  final int activeUsersCount;
  final int yachtsCount;
  final int reportedReviewsCount;
  final List<PopularYachtDtoModel> mostPopularYachts;
  final List<RevenueByPeriodDtoModel> revenueByMonth;
  final List<ReservationsByCityDtoModel> reservationsByCity;

  StatisticsDtoModel({
    required this.totalBookings,
    required this.totalRevenue,
    required this.activeUsersCount,
    required this.yachtsCount,
    required this.reportedReviewsCount,
    required this.mostPopularYachts,
    required this.revenueByMonth,
    required this.reservationsByCity,
  });

  factory StatisticsDtoModel.fromJson(Map<String, dynamic> json) {
    final popular = (json['mostPopularYachts'] as List<dynamic>? ?? [])
        .map((e) => PopularYachtDtoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final revByMonth = (json['revenueByMonth'] as List<dynamic>? ?? [])
        .map((e) => RevenueByPeriodDtoModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final byCity = (json['reservationsByCity'] as List<dynamic>? ?? [])
        .map((e) => ReservationsByCityDtoModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return StatisticsDtoModel(
      totalBookings: json['totalBookings'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
      activeUsersCount: json['activeUsersCount'] as int? ?? 0,
      yachtsCount: json['yachtsCount'] as int? ?? 0,
      reportedReviewsCount: json['reportedReviewsCount'] as int? ?? 0,
      mostPopularYachts: popular,
      revenueByMonth: revByMonth,
      reservationsByCity: byCity,
    );
  }
}

class PopularYachtDtoModel {
  final int yachtId;
  final String yachtName;
  final int bookingCount;
  final double totalRevenue;

  PopularYachtDtoModel({
    required this.yachtId,
    required this.yachtName,
    required this.bookingCount,
    required this.totalRevenue,
  });

  factory PopularYachtDtoModel.fromJson(Map<String, dynamic> json) {
    return PopularYachtDtoModel(
      yachtId: json['yachtId'] as int? ?? 0,
      yachtName: json['yachtName'] as String? ?? '',
      bookingCount: json['bookingCount'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RevenueByPeriodDtoModel {
  final int year;
  final int month;
  final double revenue;
  final int bookingCount;

  RevenueByPeriodDtoModel({
    required this.year,
    required this.month,
    required this.revenue,
    required this.bookingCount,
  });

  factory RevenueByPeriodDtoModel.fromJson(Map<String, dynamic> json) {
    return RevenueByPeriodDtoModel(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
      bookingCount: json['bookingCount'] as int? ?? 0,
    );
  }
}

class ReservationsByCityDtoModel {
  final String cityName;
  final int reservationCount;
  final double revenue;

  ReservationsByCityDtoModel({
    required this.cityName,
    required this.reservationCount,
    required this.revenue,
  });

  factory ReservationsByCityDtoModel.fromJson(Map<String, dynamic> json) {
    return ReservationsByCityDtoModel(
      cityName: json['cityName'] as String? ?? '',
      reservationCount: json['reservationCount'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0,
    );
  }
}

