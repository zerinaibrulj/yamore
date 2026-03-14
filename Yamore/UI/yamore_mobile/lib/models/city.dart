class CityModel {
  final int cityId;
  final int countryId;
  final String name;

  CityModel({
    required this.cityId,
    required this.countryId,
    required this.name,
  });

  factory CityModel.empty() => CityModel(cityId: -1, countryId: -1, name: '');

  factory CityModel.fromJson(Map<String, dynamic> json) {
    final cid = json['cityId'] ?? json['CityId'];
    final coid = json['countryId'] ?? json['CountryId'];
    final n = json['name'] ?? json['Name'];
    return CityModel(
      cityId: cid is int ? cid : (cid is num ? cid.toInt() : -1),
      countryId: coid is int ? coid : (coid is num ? coid.toInt() : -1),
      name: n is String ? n : '',
    );
  }
}

