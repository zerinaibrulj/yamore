import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/yacht_overview.dart';
import '../models/yacht_detail.dart';
import '../models/yacht_image.dart';
import '../models/yacht_availability.dart';
import '../models/city.dart';
import '../models/country.dart';
import '../models/yacht_category.dart';
import '../models/user.dart';
import '../models/statistics.dart';
import '../models/paged_users.dart';
import '../models/review.dart';
import '../models/service_category.dart';
import '../models/service_model.dart';
import '../models/reservation.dart';
import '../models/route.dart';
import '../models/weather_forecast.dart';

class ApiService {
  final String baseUrl;
  final String? username;
  final String? password;

  ApiService({
    this.baseUrl = 'http://localhost:5096',
    this.username,
    this.password,
  });

  Map<String, String> get authHeaders {
    final headers = <String, String>{};
    if (username != null && password != null && username!.isNotEmpty) {
      final credentials = base64Encode(utf8.encode('$username:$password'));
      headers['Authorization'] = 'Basic $credentials';
    }
    return headers;
  }

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
    int? capacityMin,
    double? priceMin,
    double? priceMax,
    DateTime? availableFrom,
    DateTime? availableTo,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    if (name != null && name.isNotEmpty) query['NameGTE'] = name;
    if (locationId != null) query['LocationId'] = locationId.toString();
    if (capacityMin != null) query['CapacityMin'] = capacityMin.toString();
    if (priceMin != null) query['PricePerDayMin'] = priceMin.toString();
    if (priceMax != null) query['PricePerDayMax'] = priceMax.toString();
    if (availableFrom != null && availableTo != null) {
      query['AvailableFrom'] = availableFrom.toIso8601String();
      query['AvailableTo'] = availableTo.toIso8601String();
    }
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

  Future<PagedYachtOverview> getMyYachts({
    int? page,
    int? pageSize,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    final uri = Uri.parse('$baseUrl/Yachts/owner/my')
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

  /// Move yacht to active (visible to users). Allowed from draft.
  Future<void> activateYacht(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id/activate');
    final response = await http.put(uri, headers: _headers, body: '{}');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Move yacht to hidden (not visible). Allowed from draft or active.
  Future<void> hideYacht(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id/hide');
    final response = await http.put(uri, headers: _headers, body: '{}');
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  /// Move yacht from hidden back to draft. Allowed from hidden only.
  Future<void> setYachtToDraft(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id/edit');
    final response = await http.put(uri, headers: _headers, body: '{}');
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
    final list = json['resultList'] as List<dynamic>? ?? json['ResultList'] as List<dynamic>? ?? [];
    return list.map((e) => CityModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> insertCity({required int countryId, required String name}) async {
    final uri = Uri.parse('$baseUrl/City');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'CountryId': countryId, 'Name': name}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> updateCity(int id, {required int countryId, required String name}) async {
    final uri = Uri.parse('$baseUrl/City/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({'CountryId': countryId, 'Name': name}),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> deleteCity(int id) async {
    final uri = Uri.parse('$baseUrl/City/$id');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<List<CountryModel>> getCountries() async {
    final uri = Uri.parse('$baseUrl/Country').replace(
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
    final list = json['resultList'] as List<dynamic>? ?? json['ResultList'] as List<dynamic>? ?? [];
    return list.map((e) => CountryModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> insertCountry({required String name}) async {
    final uri = Uri.parse('$baseUrl/Country');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'Name': name}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> updateCountry(int id, {required String name}) async {
    final uri = Uri.parse('$baseUrl/Country/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({'Name': name}),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> deleteCountry(int id) async {
    final uri = Uri.parse('$baseUrl/Country/$id');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
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

  Future<void> insertYachtCategory({required String name}) async {
    final uri = Uri.parse('$baseUrl/YachtCategory');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'Name': name}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> updateYachtCategory(int id, {required String name}) async {
    final uri = Uri.parse('$baseUrl/YachtCategory/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({'Name': name}),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> deleteYachtCategory(int id) async {
    final uri = Uri.parse('$baseUrl/YachtCategory/$id');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
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

  Future<AppUser> updateProfile({
    required int userId,
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
  }) async {
    final uri = Uri.parse('$baseUrl/Users/$userId');
    final body = <String, dynamic>{
      'FirstName': firstName,
      'LastName': lastName,
      'Phone': phone,
    };
    if (email != null && email.isNotEmpty) {
      body['Email'] = email;
    }
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

  Future<AppUser> changePassword({
    required int userId,
    String? oldPassword,
    required String newPassword,
  }) async {
    final uri = Uri.parse('$baseUrl/Users/$userId');
    final user = await getUserById(userId);
    final body = <String, dynamic>{
      'FirstName': user.firstName,
      'LastName': user.lastName,
      'Phone': user.phone,
      'Password': newPassword,
      'PasswordConfirmation': newPassword,
    };
    if (oldPassword != null && oldPassword.isNotEmpty) {
      body['OldPassword'] = oldPassword;
    }
    if (user.email != null && user.email!.isNotEmpty) {
      body['Email'] = user.email;
    }
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

  Future<AppUser> getUserById(int id) async {
    final uri = Uri.parse('$baseUrl/Users/$id');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return AppUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Duration> testConnection() async {
    final stopwatch = Stopwatch()..start();
    final uri = Uri.parse('$baseUrl/Yachts/admin/overview')
        .replace(queryParameters: {'Page': '0', 'PageSize': '1'});
    final response = await http.get(uri, headers: _headers).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw ApiException(0, 'Connection timed out after 10 seconds.'),
    );
    stopwatch.stop();
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return stopwatch.elapsed;
  }

  // ── Yacht Images ──

  String yachtImageUrl(int imageId) => '$baseUrl/YachtImages/$imageId';

  Future<List<YachtImageModel>> getYachtImages(int yachtId) async {
    final uri = Uri.parse('$baseUrl/YachtImages/byYacht/$yachtId');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final decoded = jsonDecode(response.body);
    List<dynamic> list;
    if (decoded is List<dynamic>) {
      list = decoded;
    } else if (decoded is Map<String, dynamic>) {
      list = (decoded['resultList'] ?? decoded['ResultList']
              ?? decoded['data'] ?? decoded['Data']
              ?? decoded['items'] ?? decoded['Items'] ?? []) as List<dynamic>? ?? [];
    } else {
      list = [];
    }
    return list
        .map((e) => YachtImageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<YachtImageModel> uploadYachtImage(int yachtId, String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final base64Data = base64Encode(bytes);
    final ext = filePath.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png'
        : ext == 'webp' ? 'image/webp'
        : 'image/jpeg';

    final uri = Uri.parse('$baseUrl/YachtImages/upload/$yachtId');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'ImageDataBase64': base64Data,
        'ContentType': contentType,
        'FileName': filePath.split(Platform.pathSeparator).last,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
    return YachtImageModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteYachtImage(int imageId) async {
    final uri = Uri.parse('$baseUrl/YachtImages/$imageId');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> setYachtImageThumbnail(int imageId) async {
    final uri = Uri.parse('$baseUrl/YachtImages/$imageId/thumbnail');
    final response = await http.put(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ── Notifications ──

  Future<void> sendNotification({required int userId, required String message}) async {
    final uri = Uri.parse('$baseUrl/Notification');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'UserId': userId,
        'Message': message,
        'CreatedAt': DateTime.now().toUtc().toIso8601String(),
        'IsRead': false,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ── Reviews ──

  Future<PagedReviews> getReviews({
    int? page,
    int? pageSize,
    int? yachtId,
    int? userId,
    bool? isReported,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    if (yachtId != null) query['YachtId'] = yachtId.toString();
    if (userId != null) query['UserId'] = userId.toString();
    if (isReported != null) query['IsReported'] = isReported.toString();
    final uri = Uri.parse('$baseUrl/Review')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return PagedReviews.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Review> createReview({
    required int reservationId,
    required int userId,
    required int yachtId,
    required int rating,
    String? comment,
  }) async {
    final uri = Uri.parse('$baseUrl/Review');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'ReservationId': reservationId,
        'UserId': userId,
        'YachtId': yachtId,
        'Rating': rating,
        'Comment': comment,
        'DatePosted': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
    return Review.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Review> updateReview({
    required int reviewId,
    required int reservationId,
    required int userId,
    required int yachtId,
    required int rating,
    String? comment,
  }) async {
    final uri = Uri.parse('$baseUrl/Review/$reviewId');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'ReservationId': reservationId,
        'UserId': userId,
        'YachtId': yachtId,
        'Rating': rating,
        'Comment': comment,
        'DatePosted': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return Review.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteReview(int id) async {
    final uri = Uri.parse('$baseUrl/Review/$id');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> reportReview(int id) async {
    final uri = Uri.parse('$baseUrl/Review/$id/report');
    final response = await http.put(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> unreportReview(int id) async {
    final uri = Uri.parse('$baseUrl/Review/$id/unreport');
    final response = await http.put(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> respondToReview(int id, String ownerResponse) async {
    final uri = Uri.parse('$baseUrl/Review/$id/respond');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({'OwnerResponse': ownerResponse}),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ── Yacht Availability ──

  Future<PagedYachtAvailabilities> getYachtAvailabilities({
    required int yachtId,
    int? page,
    int? pageSize,
  }) async {
    final query = <String, String>{
      'YachtId': yachtId.toString(),
    };
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    final uri = Uri.parse('$baseUrl/YachtAvailability')
        .replace(queryParameters: query);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return PagedYachtAvailabilities.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> insertYachtAvailability({
    required int yachtId,
    required DateTime startDate,
    required DateTime endDate,
    required bool isBlocked,
    String? note,
  }) async {
    final uri = Uri.parse('$baseUrl/YachtAvailability');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'YachtId': yachtId,
        'StartDate': startDate.toUtc().toIso8601String(),
        'EndDate': endDate.toUtc().toIso8601String(),
        'IsBlocked': isBlocked,
        'Note': note,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> deleteYachtAvailability(int id) async {
    final uri = Uri.parse('$baseUrl/YachtAvailability/$id');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ── Yacht Services (many-to-many) ──

  Future<List<int>> getYachtServiceIds(int yachtId) async {
    final uri = Uri.parse('$baseUrl/YachtService')
        .replace(queryParameters: {'YachtId': yachtId.toString(), 'PageSize': '200'});
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['resultList'] ?? json['ResultList'] ?? []) as List;
    return list.map((e) => e['serviceId'] as int).toList();
  }

  Future<void> assignYachtService({required int yachtId, required int serviceId}) async {
    final uri = Uri.parse('$baseUrl/YachtService');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({'YachtId': yachtId, 'ServiceId': serviceId}),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> removeYachtService({required int yachtId, required int serviceId}) async {
    final uri = Uri.parse('$baseUrl/YachtService')
        .replace(queryParameters: {'YachtId': yachtId.toString(), 'ServiceId': serviceId.toString(), 'PageSize': '1'});
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['resultList'] ?? json['ResultList'] ?? []) as List;
    if (list.isEmpty) return;
    final ysId = list.first['yachtServiceId'] as int;
    final delUri = Uri.parse('$baseUrl/YachtService/$ysId');
    final delResp = await http.delete(delUri, headers: _headers);
    if (delResp.statusCode != 200) {
      throw ApiException(delResp.statusCode, delResp.body);
    }
  }

  // ── Service Categories ──

  Future<PagedServiceCategories> getServiceCategories({
    int? page,
    int? pageSize,
    String? name,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    if (name != null && name.isNotEmpty) query['Name'] = name;
    final uri = Uri.parse('$baseUrl/ServiceCategory')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return PagedServiceCategories.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> insertServiceCategory({
    required String name,
    String? description,
  }) async {
    final uri = Uri.parse('$baseUrl/ServiceCategory');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'Name': name,
        'Description': description,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> updateServiceCategory(int id, {String? name, String? description}) async {
    final uri = Uri.parse('$baseUrl/ServiceCategory/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'Name': name,
        'Description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> deleteServiceCategory(int id) async {
    final uri = Uri.parse('$baseUrl/ServiceCategory/$id');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ── Services ──

  Future<PagedServices> getServices({
    int? page,
    int? pageSize,
    String? nameGTE,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    if (nameGTE != null && nameGTE.isNotEmpty) query['NameGTE'] = nameGTE;
    final uri = Uri.parse('$baseUrl/Service')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return PagedServices.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> insertService({
    required String name,
    String? description,
    double? price,
    int? serviceCategoryId,
  }) async {
    final uri = Uri.parse('$baseUrl/Service');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'Name': name,
        'Description': description,
        'Price': price,
        'ServiceCategoryId': serviceCategoryId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> updateService(int id, {
    required String name,
    String? description,
    double? price,
    int? serviceCategoryId,
  }) async {
    final uri = Uri.parse('$baseUrl/Service/$id');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'Name': name,
        'Description': description,
        'Price': price,
        'ServiceCategoryId': serviceCategoryId,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> deleteService(int id) async {
    final uri = Uri.parse('$baseUrl/Service/$id');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ── Reservations ──

  Future<PagedReservations> getReservations({
    int? page,
    int? pageSize,
    int? userId,
    int? yachtId,
    String? status,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    if (userId != null) query['UserId'] = userId.toString();
    if (yachtId != null) query['YachtId'] = yachtId.toString();
    if (status != null && status.isNotEmpty) query['Status'] = status;
    final uri = Uri.parse('$baseUrl/Reservation')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return PagedReservations.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // ── Routes & Weather ──

  Future<List<RouteModel>> getRoutesForYacht(int yachtId) async {
    final uri = Uri.parse('$baseUrl/Route').replace(
      queryParameters: {
        'Page': '0',
        'PageSize': '100',
        'YachtId': yachtId.toString(),
      },
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['resultList'] ?? json['ResultList'] ?? []) as List;
    return list
        .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RouteModel>> getRoutes({
    int? page,
    int? pageSize,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    final uri = Uri.parse('$baseUrl/Route')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['resultList'] ?? json['ResultList'] ?? []) as List;
    return list
        .map((e) => RouteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RouteModel> insertRoute({
    required int yachtId,
    required int startCityId,
    required int endCityId,
    int? estimatedDurationHours,
    String? description,
  }) async {
    final uri = Uri.parse('$baseUrl/Route');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'YachtId': yachtId,
        'StartCityId': startCityId,
        'EndCityId': endCityId,
        'EstimatedDurationHours': estimatedDurationHours,
        'Description': description,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
    return RouteModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<RouteModel> updateRoute({
    required int routeId,
    required int yachtId,
    required int startCityId,
    required int endCityId,
    int? estimatedDurationHours,
    String? description,
  }) async {
    final uri = Uri.parse('$baseUrl/Route/$routeId');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'YachtId': yachtId,
        'StartCityId': startCityId,
        'EndCityId': endCityId,
        'EstimatedDurationHours': estimatedDurationHours,
        'Description': description,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return RouteModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteRoute(int routeId) async {
    final uri = Uri.parse('$baseUrl/Route/$routeId');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<List<WeatherForecastModel>> getWeatherForRoute(int routeId) async {
    final uri = Uri.parse('$baseUrl/WeatherForecast').replace(
      queryParameters: {
        'Page': '0',
        'PageSize': '10',
        'RouteId': routeId.toString(),
      },
    );
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['resultList'] ?? json['ResultList'] ?? []) as List;
    return list
        .map((e) => WeatherForecastModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<WeatherForecastModel>> getWeatherForecasts({
    int? routeId,
    int? page,
    int? pageSize,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    if (routeId != null) query['RouteId'] = routeId.toString();
    final uri = Uri.parse('$baseUrl/WeatherForecast')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['resultList'] ?? json['ResultList'] ?? []) as List;
    return list
        .map((e) => WeatherForecastModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WeatherForecastModel> insertWeatherForecast({
    required int routeId,
    DateTime? forecastDate,
    double? temperature,
    String? condition,
    double? windSpeed,
  }) async {
    final uri = Uri.parse('$baseUrl/WeatherForecast');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'RouteId': routeId,
        'ForecastDate': forecastDate?.toUtc().toIso8601String(),
        'Temperature': temperature,
        'Condition': condition,
        'WindSpeed': windSpeed,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
    return WeatherForecastModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<WeatherForecastModel> updateWeatherForecast({
    required int forecastId,
    required int routeId,
    DateTime? forecastDate,
    double? temperature,
    String? condition,
    double? windSpeed,
  }) async {
    final uri = Uri.parse('$baseUrl/WeatherForecast/$forecastId');
    final response = await http.put(
      uri,
      headers: _headers,
      body: jsonEncode({
        'RouteId': routeId,
        'ForecastDate': forecastDate?.toUtc().toIso8601String(),
        'Temperature': temperature,
        'Condition': condition,
        'WindSpeed': windSpeed,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    return WeatherForecastModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteWeatherForecast(int forecastId) async {
    final uri = Uri.parse('$baseUrl/WeatherForecast/$forecastId');
    final response = await http.delete(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<Reservation> createReservation({
    required int userId,
    required int yachtId,
    required DateTime startDate,
    required DateTime endDate,
    double? totalPrice,
    String status = 'Pending',
  }) async {
    final uri = Uri.parse('$baseUrl/Reservation');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'UserId': userId,
        'YachtId': yachtId,
        'StartDate': startDate.toUtc().toIso8601String(),
        'EndDate': endDate.toUtc().toIso8601String(),
        'TotalPrice': totalPrice,
        'Status': status,
        'CreatedAt': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
    return Reservation.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> cancelReservation(int id) async {
    final uri = Uri.parse('$baseUrl/Reservation/$id/cancel');
    final response = await http.put(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  Future<void> confirmReservation(int id) async {
    final uri = Uri.parse('$baseUrl/Reservation/$id/confirm');
    final response = await http.put(uri, headers: _headers);
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ── Reservation Services (extras) ──

  Future<void> addServiceToReservation({
    required int reservationId,
    required int serviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/ReservationService');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'ReservationId': reservationId,
        'ServiceId': serviceId,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(response.statusCode, response.body);
    }
  }

  // ── Payment (Stripe + offline) ──

  /// Fetches Stripe publishable key (endpoint is AllowAnonymous). Use to init Stripe SDK.
  Future<String> getStripePublishableKey() async {
    final uri = Uri.parse('$baseUrl/Payment/stripe-config');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return '';
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return (map['publishableKey'] ?? map['PublishableKey'] ?? '') as String;
  }

  /// Creates a Stripe PaymentIntent for card payment. Returns clientSecret and paymentIntentId.
  Future<PaymentIntentResult> createPaymentIntent({
    required int reservationId,
    required double amount,
    String paymentMethod = 'stripe',
  }) async {
    final uri = Uri.parse('$baseUrl/Payment/create-intent');
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode({
        'reservationId': reservationId,
        'ReservationId': reservationId,
        'amount': amount,
        'Amount': amount,
        'paymentMethod': paymentMethod,
        'PaymentMethod': paymentMethod,
      }),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return PaymentIntentResult(
      clientSecret: map['clientSecret'] as String? ?? map['ClientSecret'] as String?,
      paymentIntentId: map['paymentIntentId'] as String? ?? map['PaymentIntentId'] as String?,
      status: map['status'] as String? ?? map['Status'] as String?,
    );
  }

  /// Confirms payment: for card pass paymentIntentId; for cash/bank pass paymentMethod only.
  Future<String> confirmPayment({
    required int reservationId,
    String? paymentIntentId,
    String? paymentMethod,
  }) async {
    final uri = Uri.parse('$baseUrl/Payment/confirm');
    final body = <String, dynamic>{
      'reservationId': reservationId,
      'ReservationId': reservationId,
    };
    if (paymentIntentId != null && paymentIntentId.isNotEmpty) {
      body['paymentIntentId'] = paymentIntentId;
      body['PaymentIntentId'] = paymentIntentId;
    }
    if (paymentMethod != null && paymentMethod.isNotEmpty) {
      body['paymentMethod'] = paymentMethod;
      body['PaymentMethod'] = paymentMethod;
    }
    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw ApiException(response.statusCode, response.body);
    }
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return map['status'] as String? ?? map['Status'] as String? ?? 'succeeded';
  }
}

class PaymentIntentResult {
  final String? clientSecret;
  final String? paymentIntentId;
  final String? status;
  PaymentIntentResult({this.clientSecret, this.paymentIntentId, this.status});
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);
  @override
  String toString() => 'ApiException: $statusCode $body';
}
