class RouteModel {
  final int routeId;
  final int yachtId;
  final int startCityId;
  final int endCityId;
  final int? estimatedDurationHours;
  final String? description;

  RouteModel({
    required this.routeId,
    required this.yachtId,
    required this.startCityId,
    required this.endCityId,
    this.estimatedDurationHours,
    this.description,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      routeId: json['routeId'] as int,
      yachtId: json['yachtId'] as int,
      startCityId: json['startCityId'] as int,
      endCityId: json['endCityId'] as int,
      estimatedDurationHours: json['estimatedDurationHours'] as int?,
      description: json['description'] as String?,
    );
  }
}

