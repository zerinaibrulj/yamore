class WeatherForecastModel {
  final int forecastId;
  final int routeId;
  final DateTime? forecastDate;
  final double? temperature;
  final String? condition;
  final double? windSpeed;

  WeatherForecastModel({
    required this.forecastId,
    required this.routeId,
    this.forecastDate,
    this.temperature,
    this.condition,
    this.windSpeed,
  });

  factory WeatherForecastModel.fromJson(Map<String, dynamic> json) {
    return WeatherForecastModel(
      forecastId: json['forecastId'] as int,
      routeId: json['routeId'] as int,
      forecastDate: json['forecastDate'] != null
          ? DateTime.tryParse(json['forecastDate'] as String)
          : null,
      temperature: (json['temperature'] as num?)?.toDouble(),
      condition: json['condition'] as String?,
      windSpeed: (json['windSpeed'] as num?)?.toDouble(),
    );
  }
}

