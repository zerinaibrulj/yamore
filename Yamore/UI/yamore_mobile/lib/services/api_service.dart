import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/yacht_overview.dart';
import '../models/yacht_detail.dart';
import '../models/city.dart';
import '../models/yacht_category.dart';

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
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException: $statusCode $body';
}
