import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'api_exception.dart';
import 'api_response_handler.dart';
import 'auth_service.dart';
import '../utils/payment_platform.dart';
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
import '../models/notification.dart';
import '../models/news_item.dart';

export 'api_exception.dart';

class ApiService {
  final String baseUrl;
  final AuthService? auth;

  ApiService({
    required this.baseUrl,
    this.auth,
  });

  /// Synchronous; current access token. Call [AuthService.ensureValidAccess] before
  /// loading images that require auth, if the session was idle a long time.
  Map<String, String> get authHeaders => auth?.authHeaders ?? const {};

  Future<Map<String, String>> _httpHeaders() async {
    if (auth != null) {
      await auth!.ensureValidAccess();
    }
    return _baseHeaders();
  }

  Map<String, String> _baseHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Yamore-Client': yamoreClientKindHeaderValue,
    };
    final t = auth?.accessToken;
    if (t != null && t.isNotEmpty) {
      headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  void _ensureSuccess(http.Response response, {bool allow201 = false}) {
    ApiResponseHandler.ensureSuccess(response, allow201: allow201);
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
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    return PagedYachtOverview.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// Personalized recommendations; the API uses the JWT (non-admins cannot target another [userId]).
  Future<PagedYachtOverview> getRecommendations({
    int? userId,
    int page = 0,
    int pageSize = 10,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };
    if (userId != null) {
      query['userId'] = userId.toString();
    }
    final uri = Uri.parse('$baseUrl/Yachts/recommendations')
        .replace(queryParameters: query);
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    return PagedYachtOverview.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<YachtDetail> getYachtById(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id');
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    return YachtDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<YachtDetail> createYacht(YachtDetail yacht) async {
    final uri = Uri.parse('$baseUrl/Yachts');
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode(yacht.toJsonForSave()),
    );
    _ensureSuccess(response, allow201: true);
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
      headers: await _httpHeaders(),
      body: jsonEncode(yacht.toJsonForSave()),
    );
    _ensureSuccess(response);
    return YachtDetail.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteYacht(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  /// Move yacht to active (visible to users). Allowed from draft.
  Future<void> activateYacht(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id/activate');
    final response = await http.put(uri, headers: await _httpHeaders(), body: '{}');
    _ensureSuccess(response);
  }

  /// Move yacht to hidden (not visible). Allowed from draft or active.
  Future<void> hideYacht(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id/hide');
    final response = await http.put(uri, headers: await _httpHeaders(), body: '{}');
    _ensureSuccess(response);
  }

  /// Move yacht from hidden back to draft. Allowed from hidden only.
  Future<void> setYachtToDraft(int id) async {
    final uri = Uri.parse('$baseUrl/Yachts/$id/edit');
    final response = await http.put(uri, headers: await _httpHeaders(), body: '{}');
    _ensureSuccess(response);
  }

  /// Paged list; [nameGte] is a name prefix (API `NameGTE` / starts-with).
  Future<PagedCities> getCitiesPaged({
    int page = 0,
    int pageSize = 10,
    String? nameGte,
  }) async {
    final q = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
    };
    final t = nameGte?.trim();
    if (t != null && t.isNotEmpty) {
      q['NameGTE'] = t;
    }
    final uri = Uri.parse('$baseUrl/City').replace(queryParameters: q);
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    return PagedCities.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// All cities (paged loop). Use for dropdowns and validation, not the admin table.
  Future<List<CityModel>> getAllCities() async {
    const size = 200;
    var page = 0;
    final all = <CityModel>[];
    int? total;
    while (true) {
      final p = await getCitiesPaged(page: page, pageSize: size, nameGte: null);
      all.addAll(p.resultList);
      total = p.count ?? total;
      if (p.resultList.isEmpty) break;
      if (total != null && all.length >= total) break;
      if (p.resultList.length < size) break;
      page++;
    }
    return all;
  }

  /// Backward-compatible: all cities (same as [getAllCities]).
  Future<List<CityModel>> getCities() => getAllCities();

  Future<void> insertCity({required int countryId, required String name}) async {
    final uri = Uri.parse('$baseUrl/City');
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({'CountryId': countryId, 'Name': name}),
    );
    _ensureSuccess(response, allow201: true);
  }

  Future<void> updateCity(int id, {required int countryId, required String name}) async {
    final uri = Uri.parse('$baseUrl/City/$id');
    final response = await http.put(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({'CountryId': countryId, 'Name': name}),
    );
    _ensureSuccess(response);
  }

  Future<void> deleteCity(int id) async {
    final uri = Uri.parse('$baseUrl/City/$id');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  /// Paged list; [nameGte] is a name prefix (API `NameGTE` / starts-with).
  Future<PagedCountries> getCountriesPaged({
    int page = 0,
    int pageSize = 10,
    String? nameGte,
  }) async {
    final q = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
    };
    final t = nameGte?.trim();
    if (t != null && t.isNotEmpty) {
      q['NameGTE'] = t;
    }
    final uri = Uri.parse('$baseUrl/Country').replace(queryParameters: q);
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    return PagedCountries.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// All countries (paged loop). Use for dropdowns and country name lookup, not the admin table.
  Future<List<CountryModel>> getAllCountries() async {
    const size = 200;
    var page = 0;
    final all = <CountryModel>[];
    int? total;
    while (true) {
      final p = await getCountriesPaged(page: page, pageSize: size, nameGte: null);
      all.addAll(p.resultList);
      total = p.count ?? total;
      if (p.resultList.isEmpty) break;
      if (total != null && all.length >= total) break;
      if (p.resultList.length < size) break;
      page++;
    }
    return all;
  }

  /// Backward-compatible: all countries (same as [getAllCountries]).
  Future<List<CountryModel>> getCountries() => getAllCountries();

  Future<void> insertCountry({required String name}) async {
    final uri = Uri.parse('$baseUrl/Country');
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({'Name': name}),
    );
    _ensureSuccess(response, allow201: true);
  }

  Future<void> updateCountry(int id, {required String name}) async {
    final uri = Uri.parse('$baseUrl/Country/$id');
    final response = await http.put(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({'Name': name}),
    );
    _ensureSuccess(response);
  }

  Future<void> deleteCountry(int id) async {
    final uri = Uri.parse('$baseUrl/Country/$id');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<List<YachtCategoryModel>> getYachtCategories() async {
    final uri = Uri.parse('$baseUrl/YachtCategory').replace(
      queryParameters: {
        'Page': '0',
        'PageSize': '100',
      },
    );
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode({'Name': name}),
    );
    _ensureSuccess(response, allow201: true);
  }

  Future<void> updateYachtCategory(int id, {required String name}) async {
    final uri = Uri.parse('$baseUrl/YachtCategory/$id');
    final response = await http.put(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({'Name': name}),
    );
    _ensureSuccess(response);
  }

  Future<void> deleteYachtCategory(int id) async {
    final uri = Uri.parse('$baseUrl/YachtCategory/$id');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  /// All users who have the YachtOwner/Owner role, sorted by display name (fetches all pages).
  Future<List<AppUser>> getOwners() async {
    const pageSize = 100;
    final all = <AppUser>[];
    var page = 0;
    while (true) {
      final uri = Uri.parse('$baseUrl/Users/owners').replace(
        queryParameters: {
          'Page': page.toString(),
          'PageSize': pageSize.toString(),
        },
      );
      final response = await http.get(uri, headers: await _httpHeaders());
      _ensureSuccess(response);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final list = json['resultList'] as List<dynamic>? ?? [];
      final total = (json['count'] as num?)?.toInt() ?? 0;
      all.addAll(
        list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)),
      );
      if (list.length < pageSize || all.length >= total) break;
      page++;
    }
    all.sort((a, b) => a.displayName.compareTo(b.displayName));
    return all;
  }

  Future<StatisticsDtoModel> getAdminStatistics({int? year}) async {
    final uri = Uri.parse('$baseUrl/Statistics/admin').replace(
      queryParameters:
          year != null ? <String, String>{'year': year.toString()} : null,
    );
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode(body),
    );
    _ensureSuccess(response, allow201: true);
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
    final response = await http.put(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
    return AppUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteUser(int id) async {
    final uri = Uri.parse('$baseUrl/Users/$id');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<void> suspendUser(int id) async {
    final uri = Uri.parse('$baseUrl/Users/$id/suspend');
    final response = await http.put(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<void> activateUser(int id) async {
    final uri = Uri.parse('$baseUrl/Users/$id/activate');
    final response = await http.put(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
    return AppUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AppUser> getUserById(int id) async {
    final uri = Uri.parse('$baseUrl/Users/$id');
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    return AppUser.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Duration> testConnection() async {
    final stopwatch = Stopwatch()..start();
    final uri = Uri.parse('$baseUrl/Yachts/admin/overview')
        .replace(queryParameters: {'Page': '0', 'PageSize': '1'});
    final response = await http.get(uri, headers: await _httpHeaders()).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw ApiException(0, 'Connection timed out after 10 seconds.'),
    );
    stopwatch.stop();
    _ensureSuccess(response);
    return stopwatch.elapsed;
  }

  String yachtImageUrl(int imageId) => '$baseUrl/YachtImages/$imageId';

  Future<List<YachtImageModel>> getYachtImages(int yachtId) async {
    const pageSize = 100;
    final all = <YachtImageModel>[];
    var page = 0;
    while (true) {
      final uri = Uri.parse('$baseUrl/YachtImages/byYacht/$yachtId').replace(
        queryParameters: {
          'Page': page.toString(),
          'PageSize': pageSize.toString(),
        },
      );
      final response = await http.get(uri, headers: await _httpHeaders());
      _ensureSuccess(response);
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (decoded['resultList'] ?? decoded['ResultList'] ?? [])
          as List<dynamic>? ?? [];
      final totalRaw = decoded['count'] ?? decoded['Count'];
      final total = totalRaw is int
          ? totalRaw
          : totalRaw is num
              ? totalRaw.toInt()
              : 0;
      all.addAll(
        list.map((e) => YachtImageModel.fromJson(e as Map<String, dynamic>)),
      );
      if (list.length < pageSize || all.length >= total) break;
      page++;
    }
    return all;
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'ImageDataBase64': base64Data,
        'ContentType': contentType,
        'FileName': filePath.split(Platform.pathSeparator).last,
      }),
    );
    _ensureSuccess(response, allow201: true);
    return YachtImageModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteYachtImage(int imageId) async {
    final uri = Uri.parse('$baseUrl/YachtImages/$imageId');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<void> setYachtImageThumbnail(int imageId) async {
    final uri = Uri.parse('$baseUrl/YachtImages/$imageId/thumbnail');
    final response = await http.put(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<void> sendNotification({
    required int userId,
    required String message,
    String? title,
  }) async {
    final uri = Uri.parse('$baseUrl/Notification');
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({
        'UserId': userId,
        'Title': title ?? 'Yamore',
        'Message': message,
        'CreatedAt': DateTime.now().toUtc().toIso8601String(),
        'IsRead': false,
      }),
    );
    _ensureSuccess(response, allow201: true);
  }

  Future<void> markNotificationRead(int notificationId) async {
    final uri = Uri.parse('$baseUrl/Notification/$notificationId/mark-read');
    final response = await http.put(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<PagedNewsItems> getNews({
    int page = 0,
    int pageSize = 20,
    String? titleContains,
    String? textContains,
    DateTime? createdFrom,
    DateTime? createdTo,
  }) async {
    final q = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
    };
    final t = titleContains?.trim();
    final x = textContains?.trim();
    if (t != null && t.isNotEmpty) {
      q['TitleContains'] = t;
    }
    if (x != null && x.isNotEmpty) {
      q['TextContains'] = x;
    }
    if (createdFrom != null) {
      q['CreatedFrom'] = createdFrom.toUtc().toIso8601String();
    }
    if (createdTo != null) {
      q['CreatedTo'] = createdTo.toUtc().toIso8601String();
    }
    final uri = Uri.parse('$baseUrl/news').replace(queryParameters: q);
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    return PagedNewsItems.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<NewsItemModel> createNews({
    required String title,
    required String text,
    DateTime? createdAt,
  }) async {
    final uri = Uri.parse('$baseUrl/news');
    final body = <String, dynamic>{
      'Title': title,
      'Text': text,
      if (createdAt != null) 'CreatedAt': createdAt.toUtc().toIso8601String(),
    };
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode(body),
    );
    _ensureSuccess(response, allow201: true);
    return NewsItemModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteNews(int newsId) async {
    final uri = Uri.parse('$baseUrl/news/$newsId');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<void> sendWarningToUserAndOwners({
    required int userId,
    required String message,
  }) async {
    final uri = Uri.parse('$baseUrl/Notification/warning-to-user-and-owners');
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({
        'UserId': userId,
        'Message': message,
      }),
    );
    _ensureSuccess(response, allow201: true);
  }

  Future<PagedNotifications> getNotifications({
    required int userId,
    int page = 0,
    int pageSize = 20,
    bool? isRead,
  }) async {
    final query = <String, String>{
      'Page': page.toString(),
      'PageSize': pageSize.toString(),
      'UserId': userId.toString(),
    };
    if (isRead != null) {
      query['IsRead'] = isRead.toString();
    }

    final uri = Uri.parse('$baseUrl/Notification').replace(
      queryParameters: query,
    );

    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);

    return PagedNotifications.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

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
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'ReservationId': reservationId,
        'UserId': userId,
        'YachtId': yachtId,
        'Rating': rating,
        'Comment': comment,
        'DatePosted': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    _ensureSuccess(response, allow201: true);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'ReservationId': reservationId,
        'UserId': userId,
        'YachtId': yachtId,
        'Rating': rating,
        'Comment': comment,
        'DatePosted': DateTime.now().toUtc().toIso8601String(),
      }),
    );
    _ensureSuccess(response);
    return Review.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteReview(int id) async {
    final uri = Uri.parse('$baseUrl/Review/$id');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<void> reportReview(int id) async {
    final uri = Uri.parse('$baseUrl/Review/$id/report');
    final response = await http.put(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<void> unreportReview(int id) async {
    final uri = Uri.parse('$baseUrl/Review/$id/unreport');
    final response = await http.put(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<void> respondToReview(int id, String ownerResponse) async {
    final uri = Uri.parse('$baseUrl/Review/$id/respond');
    final response = await http.put(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({'OwnerResponse': ownerResponse}),
    );
    _ensureSuccess(response);
  }

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
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'YachtId': yachtId,
        'StartDate': startDate.toUtc().toIso8601String(),
        'EndDate': endDate.toUtc().toIso8601String(),
        'IsBlocked': isBlocked,
        'Note': note,
      }),
    );
    _ensureSuccess(response, allow201: true);
  }

  Future<void> deleteYachtAvailability(int id) async {
    final uri = Uri.parse('$baseUrl/YachtAvailability/$id');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  Future<List<int>> getYachtServiceIds(int yachtId) async {
    final uri = Uri.parse('$baseUrl/YachtService')
        .replace(queryParameters: {'YachtId': yachtId.toString(), 'PageSize': '200'});
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['resultList'] ?? json['ResultList'] ?? []) as List;
    return list.map((e) => e['serviceId'] as int).toList();
  }

  Future<void> assignYachtService({required int yachtId, required int serviceId}) async {
    final uri = Uri.parse('$baseUrl/YachtService');
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({'YachtId': yachtId, 'ServiceId': serviceId}),
    );
    _ensureSuccess(response, allow201: true);
  }

  Future<void> removeYachtService({required int yachtId, required int serviceId}) async {
    final uri = Uri.parse('$baseUrl/YachtService')
        .replace(queryParameters: {'YachtId': yachtId.toString(), 'ServiceId': serviceId.toString(), 'PageSize': '1'});
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final list = (json['resultList'] ?? json['ResultList'] ?? []) as List;
    if (list.isEmpty) return;
    final ysId = list.first['yachtServiceId'] as int;
    final delUri = Uri.parse('$baseUrl/YachtService/$ysId');
    final delResp = await http.delete(delUri, headers: await _httpHeaders());
    _ensureSuccess(delResp);
  }

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
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'Name': name,
        'Description': description,
      }),
    );
    _ensureSuccess(response, allow201: true);
  }

  Future<void> updateServiceCategory(int id, {String? name, String? description}) async {
    final uri = Uri.parse('$baseUrl/ServiceCategory/$id');
    final response = await http.put(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({
        'Name': name,
        'Description': description,
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> deleteServiceCategory(int id) async {
    final uri = Uri.parse('$baseUrl/ServiceCategory/$id');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

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
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'Name': name,
        'Description': description,
        'Price': price,
        'ServiceCategoryId': serviceCategoryId,
      }),
    );
    _ensureSuccess(response, allow201: true);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'Name': name,
        'Description': description,
        'Price': price,
        'ServiceCategoryId': serviceCategoryId,
      }),
    );
    _ensureSuccess(response);
  }

  Future<void> deleteService(int id) async {
    final uri = Uri.parse('$baseUrl/Service/$id');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

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
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
    return PagedReservations.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<RouteModel>> getRoutesForYacht(int yachtId) async {
    final uri = Uri.parse('$baseUrl/Route').replace(
      queryParameters: {
        'Page': '0',
        'PageSize': '100',
        'YachtId': yachtId.toString(),
      },
    );
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'YachtId': yachtId,
        'StartCityId': startCityId,
        'EndCityId': endCityId,
        'EstimatedDurationHours': estimatedDurationHours,
        'Description': description,
      }),
    );
    _ensureSuccess(response, allow201: true);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'YachtId': yachtId,
        'StartCityId': startCityId,
        'EndCityId': endCityId,
        'EstimatedDurationHours': estimatedDurationHours,
        'Description': description,
      }),
    );
    _ensureSuccess(response);
    return RouteModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteRoute(int routeId) async {
    final uri = Uri.parse('$baseUrl/Route/$routeId');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
  }

  /// When [tripStart] / [tripEnd] are set, the API returns only forecasts on those
  /// calendar days (inclusive). Omit both for all forecasts for the route.
  Future<List<WeatherForecastModel>> getWeatherForRoute(
    int routeId, {
    DateTime? tripStart,
    DateTime? tripEnd,
  }) async {
    final query = <String, String>{
      'Page': '0',
      'PageSize': '50',
      'RouteId': routeId.toString(),
    };
    if (tripStart != null) {
      query['TripStart'] = tripStart.toUtc().toIso8601String();
    }
    if (tripEnd != null) {
      query['TripEnd'] = tripEnd.toUtc().toIso8601String();
    }
    final uri = Uri.parse('$baseUrl/WeatherForecast').replace(
      queryParameters: query,
    );
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
    DateTime? tripStart,
    DateTime? tripEnd,
  }) async {
    final query = <String, String>{};
    if (page != null) query['Page'] = page.toString();
    if (pageSize != null) query['PageSize'] = pageSize.toString();
    if (routeId != null) query['RouteId'] = routeId.toString();
    if (tripStart != null) {
      query['TripStart'] = tripStart.toUtc().toIso8601String();
    }
    if (tripEnd != null) {
      query['TripEnd'] = tripEnd.toUtc().toIso8601String();
    }
    final uri = Uri.parse('$baseUrl/WeatherForecast')
        .replace(queryParameters: query.isNotEmpty ? query : null);
    final response = await http.get(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'RouteId': routeId,
        'ForecastDate': _weatherForecastDateToJson(forecastDate),
        'Temperature': temperature,
        'Condition': condition,
        'WindSpeed': windSpeed,
      }),
    );
    _ensureSuccess(response, allow201: true);
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
      headers: await _httpHeaders(),
      body: jsonEncode({
        'RouteId': routeId,
        'ForecastDate': _weatherForecastDateToJson(forecastDate),
        'Temperature': temperature,
        'Condition': condition,
        'WindSpeed': windSpeed,
      }),
    );
    _ensureSuccess(response);
    return WeatherForecastModel.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  /// ISO 8601 in the user's local time zone, without [toUtc] conversion, so
  /// the value stored and shown matches the selected date and time.
  String? _weatherForecastDateToJson(DateTime? value) {
    if (value == null) return null;
    final l = value.toLocal();
    return DateTime(
      l.year,
      l.month,
      l.day,
      l.hour,
      l.minute,
      l.second,
      l.millisecond,
      l.microsecond,
    ).toIso8601String();
  }

  Future<void> deleteWeatherForecast(int forecastId) async {
    final uri = Uri.parse('$baseUrl/WeatherForecast/$forecastId');
    final response = await http.delete(uri, headers: await _httpHeaders());
    _ensureSuccess(response);
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
      headers: await _httpHeaders(),
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
    _ensureSuccess(response, allow201: true);
    return Reservation.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<CancelReservationResult> cancelReservation(int id, {String? reason}) async {
    final uri = Uri.parse('$baseUrl/Reservation/$id/cancel');
    final response = await http.put(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({'reason': reason}),
    );
    _ensureSuccess(response);
    final hadCard = _headerEqualsTrue(
      response,
      'x-reservation-cancel-has-card-payment',
    );
    final reservation = Reservation.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
    return CancelReservationResult(
      reservation: reservation,
      hadCardPayment: hadCard,
    );
  }

  static bool _headerEqualsTrue(http.Response response, String name) {
    final want = name.toLowerCase();
    for (final e in response.headers.entries) {
      if (e.key.toLowerCase() == want) {
        return e.value.trim().toLowerCase() == 'true';
      }
    }
    return false;
  }

  /// Marks a confirmed reservation completed after the trip end time (API enforces rules).
  Future<void> completeReservation(int id) async {
    final uri = Uri.parse('$baseUrl/Reservation/$id/complete');
    final response = await http.put(uri, headers: await _httpHeaders(), body: '{}');
    _ensureSuccess(response);
  }

  /// Admin-only: reject a pending reservation with a required reason.
  Future<void> rejectReservation(int id, String reason) async {
    final uri = Uri.parse('$baseUrl/Reservation/$id/reject');
    final response = await http.put(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({'reason': reason}),
    );
    _ensureSuccess(response);
  }

  Future<void> confirmReservation(int id) async {
    final uri = Uri.parse('$baseUrl/Reservation/$id/confirm');
    final response = await http.put(uri, headers: await _httpHeaders(), body: '{}');
    _ensureSuccess(response);
  }

  Future<void> addServiceToReservation({
    required int reservationId,
    required int serviceId,
  }) async {
    final uri = Uri.parse('$baseUrl/ReservationService');
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({
        'ReservationId': reservationId,
        'ServiceId': serviceId,
      }),
    );
    _ensureSuccess(response, allow201: true);
  }

  /// Fetches Stripe publishable key (endpoint is AllowAnonymous). Use to init Stripe SDK.
  Future<String> getStripePublishableKey() async {
    final uri = Uri.parse('$baseUrl/Payment/stripe-config');
    final response = await http.get(uri, headers: await _httpHeaders());
    if (response.statusCode != 200) return '';
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return (map['publishableKey'] ?? map['PublishableKey'] ?? '') as String;
  }

  /// Starts card checkout without creating a reservation. After Stripe succeeds, call [confirmPayment] with [reservationId] 0 and the [paymentIntentId].
  Future<PaymentIntentResult> prepareCardBooking({
    required int userId,
    required int yachtId,
    required DateTime startDate,
    required DateTime endDate,
    List<int> serviceIds = const [],
  }) async {
    final uri = Uri.parse('$baseUrl/Payment/prepare-card-booking');
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({
        'userId': userId,
        'UserId': userId,
        'yachtId': yachtId,
        'YachtId': yachtId,
        'startDate': startDate.toUtc().toIso8601String(),
        'StartDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate.toUtc().toIso8601String(),
        'EndDate': endDate.toUtc().toIso8601String(),
        'serviceIds': serviceIds,
        'ServiceIds': serviceIds,
      }),
    );
    _ensureSuccess(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return PaymentIntentResult(
      clientSecret: map['clientSecret'] as String? ?? map['ClientSecret'] as String?,
      paymentIntentId: map['paymentIntentId'] as String? ?? map['PaymentIntentId'] as String?,
      status: map['status'] as String? ?? map['Status'] as String?,
    );
  }

  /// Creates a Stripe PaymentIntent for an <b>existing</b> reservation. The amount is set on the server from the booking total.
  Future<PaymentIntentResult> createPaymentIntent({
    required int reservationId,
    String paymentMethod = 'stripe',
  }) async {
    final uri = Uri.parse('$baseUrl/Payment/create-intent');
    final response = await http.post(
      uri,
      headers: await _httpHeaders(),
      body: jsonEncode({
        'reservationId': reservationId,
        'ReservationId': reservationId,
        'paymentMethod': paymentMethod,
        'PaymentMethod': paymentMethod,
      }),
    );
    _ensureSuccess(response);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    return PaymentIntentResult(
      clientSecret: map['clientSecret'] as String? ?? map['ClientSecret'] as String?,
      paymentIntentId: map['paymentIntentId'] as String? ?? map['PaymentIntentId'] as String?,
      status: map['status'] as String? ?? map['Status'] as String?,
    );
  }

  /// For new card booking: [reservationId] 0 and [paymentIntentId]. For pay-on-arrival: a real [reservationId] and [paymentMethod].
  Future<String> confirmPayment({
    int reservationId = 0,
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
      headers: await _httpHeaders(),
      body: jsonEncode(body),
    );
    _ensureSuccess(response);
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
