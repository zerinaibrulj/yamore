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

class PagedCountries {
  final int? count;
  final List<CountryModel> resultList;

  PagedCountries({this.count, required this.resultList});

  factory PagedCountries.fromJson(Map<String, dynamic> json) {
    final list = (json['resultList'] as List<dynamic>?) ??
        (json['ResultList'] as List<dynamic>?) ??
        <dynamic>[];
    return PagedCountries(
      count: json['count'] as int? ?? json['Count'] as int?,
      resultList: list
          .map((e) => CountryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
