class CityModel {
  final int cityId;
  final String name;

  CityModel({
    required this.cityId,
    required this.name,
  });

  factory CityModel.empty() => CityModel(cityId: -1, name: '');

  factory CityModel.fromJson(Map<String, dynamic> json) {
    return CityModel(
      cityId: json['cityId'] as int,
      name: json['name'] as String? ?? '',
    );
  }
}

