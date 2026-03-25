class NotificationModel {
  final int notificationId;
  final int userId;
  final String message;
  final DateTime? createdAt;
  final bool? isRead;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.message,
    this.createdAt,
    this.isRead,
  });

  static dynamic _key(
    Map<String, dynamic> json,
    String camel,
    String pascal,
  ) {
    if (json.containsKey(camel)) return json[camel];
    return json[pascal];
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final createdRaw = _key(json, 'createdAt', 'CreatedAt');
    DateTime? createdAt;
    if (createdRaw is String && createdRaw.trim().isNotEmpty) {
      createdAt = DateTime.tryParse(createdRaw);
    } else if (createdRaw is DateTime) {
      createdAt = createdRaw;
    }

    final isReadRaw = _key(json, 'isRead', 'IsRead');
    bool? isRead;
    if (isReadRaw is bool) {
      isRead = isReadRaw;
    } else if (isReadRaw is String) {
      final v = isReadRaw.toLowerCase().trim();
      if (v == 'true') isRead = true;
      if (v == 'false') isRead = false;
    }

    return NotificationModel(
      notificationId: _key(json, 'notificationId', 'NotificationId') as int,
      userId: _key(json, 'userId', 'UserId') as int,
      message: (_key(json, 'message', 'Message') as String?) ?? '',
      createdAt: createdAt,
      isRead: isRead,
    );
  }
}

class PagedNotifications {
  final int? count;
  final List<NotificationModel> resultList;

  PagedNotifications({
    this.count,
    required this.resultList,
  });

  factory PagedNotifications.fromJson(Map<String, dynamic> json) {
    final rawList = NotificationModel._key(json, 'resultList', 'ResultList');
    final list = rawList is List<dynamic> ? rawList : <dynamic>[];
    return PagedNotifications(
      count: NotificationModel._key(json, 'count', 'Count') as int?,
      resultList: list
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

