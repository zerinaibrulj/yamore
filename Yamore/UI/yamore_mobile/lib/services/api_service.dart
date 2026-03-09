import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/yacht_overview.dart';
import '../models/yacht_detail.dart';

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
  }) async {
    final query = <String, String>{};
    if (page != null) query['page'] = page.toString();
    if (pageSize != null) query['pageSize'] = pageSize.toString();
    final uri = Uri.parse('$baseUrl/Yachts/admin/overview').replace(queryParameters: query.isNotEmpty ? query : null);
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
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException: $statusCode $body';
}
