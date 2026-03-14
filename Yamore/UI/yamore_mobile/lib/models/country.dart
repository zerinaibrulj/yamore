class CountryModel {
  final int countryId;
  final String name;

  CountryModel({
    required this.countryId,
    required this.name,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) {
    final id = json['countryId'] ?? json['CountryId'];
    final n = json['name'] ?? json['Name'];
    return CountryModel(
      countryId: id is int ? id : (id is num ? id.toInt() : 0),
      name: n is String ? n : '',
    );
  }
}
