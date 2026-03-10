import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/yacht_overview.dart';
import '../models/yacht_detail.dart';
import '../models/city.dart';
import '../models/yacht_category.dart';
import '../models/user.dart';
import '../models/statistics.dart';
import '../models/paged_users.dart';

class ApiService {
  final String baseUrl;
  final String? username;
  final String? password;

  ApiService({
    this.baseUrl = 'http://localhost:5096',
    this.username,
    this.password,
  });

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (username != null && password != null && username!.isNotEmpty) {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      headers['Authorization'] = 'Basic $credentials';
    }
    return headers;
  }

  Future<PagedYachtOverview> getYachtOverviewForAdmin({
    int? page,
    int? pageSize,
    String? name,
    int? locationId,
    double? priceMin,
    double? priceMax,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    if (name != null && name.isNotEmpty) query['NameGTE'] = name;
    if (locationId != null) query['LocationId'] = locationId.toString();
    if (priceMin != null) query['PricePerDayMin'] = priceMin.toString();
    if (priceMax != null) query['PricePerDayMax'] = priceMax.toString();
    final uri = Uri.parse('$baseUrl/Yachts/admin/overview')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return PagedYachtOverview.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<YachtDetail> getYachtById(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return YachtDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<YachtDetail> createYacht(YachtDetail yacht) async {
    final uri = Uri.parse('$baseUrl/Yachts');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(yacht.toJsonForSave()),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
    return YachtDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<YachtDetail> updateYacht(YachtDetail yacht) async {
    if (yacht.yachtId == null) {
      throw ArgumentError('yachtId is required for update');
    }
    final uri = Uri.parse('$baseUrl/Yachts/${yacht.yachtId}');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(yacht.toJsonForSave()),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return YachtDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteYacht(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<List<CityModel>> getCities() async {
    final uri = Uri.parse('$baseUrl/City').replace(
      queryParameters: {
        'Page': '0',
        'PageSize': '1000',
      },
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['resultList'] as List<dynamic>? ?? [];
    return list.map((e) => CityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<YachtCategoryModel>> getYachtCategories() async {
    final uri = Uri.parse('$baseUrl/YachtCategory').replace(
      queryParameters: {
        'Page': '0',
        'PageSize': '100',
      },
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['resultList'] as List<dynamic>? ?? [];
    return list
        .map((e) => YachtCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// All users who have the YachtOwner/Owner role, sorted by display name.
  Future<List<AppUser>> getOwners() async {
    final uri = Uri.parse('$baseUrl/Users/owners');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = json['resultList'] as List<dynamic>? ?? [];
    final users =
        list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    users.sort((a, b) => a.displayName.compareTo(b.displayName));
    return users;
  }

  Future<StatisticsDtoModel> getAdminStatistics({int? year}) async {
    final uri = Uri.parse('$baseUrl/Statistics/admin').replace(
      queryParameters:
          year != null ? <String, String>{'year': year.toString()} : null,
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return StatisticsDtoModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PagedUsers> getUsers({
    int? page,
    int? pageSize,
    String? name,
    String? roleName,
    bool? status,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    if (name != null && name.isNotEmpty) {
      query['FirstNameGTE'] = name;
      query['LastNameGTE'] = name;
    }
    if (roleName != null && roleName.isNotEmpty) {
      query['RoleName'] = roleName;
    }
    if (status != null) {
      query['Status'] = status.toString();
    }
    query['IsUserRoleIncluded'] = 'true';

    final uri = Uri.parse('$baseUrl/Users')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return PagedUsers.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AppUser> createUser({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    required String username,
    required String password,
    bool status = true,
    String? roleName,
  }) async {
    final uri = Uri.parse('$baseUrl/Users');
    final body = <String, dynamic>{
      'FirstName': firstName,
      'LastName': lastName,
      'Email': email,
      'Phone': phone,
      'Username': username,
      'Password': password,
      'PasswordConfirmation': password,
      'Status': status,
    };
    if (roleName != null && roleName.isNotEmpty) {
      body['RoleName'] = roleName;
    }
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
    return AppUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AppUser> updateUser({
    required int userId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    bool? status,
    String? password,
  }) async {
    final uri = Uri.parse('$baseUrl/Users/$userId');
    final body = <String, dynamic>{
      'FirstName': firstName,
      'LastName': lastName,
      'Phone': phone,
      'Status': status,
    };
    if (email != null && email.isNotEmpty) {
      body['Email'] = email;
    }
    if (password != null && password.isNotEmpty) {
      body['Password'] = password;
      body['PasswordConfirmation'] = password;
    }
    // Email and username are omitted from update for now to keep semantics simple.
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return AppUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteUser(int id) async {
    final uri = Uri.parse('$baseUrl/Users/$id');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> suspendUser(int id) async {
    final uri = Uri.parse('$baseUrl/Users/$id/suspend');
    final response = await http.put(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> activateUser(int id) async {
    final uri = Uri.parse('$baseUrl/Users/$id/activate');
    final response = await http.put(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException: $statusCode $body';
}
