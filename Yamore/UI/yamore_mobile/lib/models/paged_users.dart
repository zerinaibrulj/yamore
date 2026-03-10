import 'user.dart';

class PagedUsers {
  final int? count;
  final List<AppUser> resultList;

  PagedUsers({this.count, required this.resultList});

  /// Helper to tolerate both camelCase and PascalCase from the API.
  static dynamic _key(Map<String, dynamic> json, String camel, String pascal) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory PagedUsers.fromJson(Map<String, dynamic> json) {
    final rawList = _key(json, 'resultList', 'ResultList');
    final list = rawList is List<dynamic> ? rawList : <dynamic>[];
    return PagedUsers(
      count: _key(json, 'count', 'Count') as int?,
      resultList:
          list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

