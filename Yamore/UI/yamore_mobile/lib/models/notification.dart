class NotificationModel {
  final int notificationId;
  final int userId;
  /// System notification heading (e.g. reservation, payment). May be empty for legacy rows.
  final String title;
  final String message;
  final DateTime? createdAt;
  final bool? isRead;

  NotificationModel({
    required this.notificationId,
    required this.userId,
    this.title = '',
    required this.message,
    this.createdAt,
    this.isRead,
  });

  String get displayTitle {
    if (title.trim().isNotEmpty) return title.trim();
    if (message.trim().isNotEmpty) {
      final oneLine = message.trim().split(RegExp(r'[\r\n]')).first;
      return oneLine.length > 60 ? '${oneLine.substring(0, 60)}…' : oneLine;
    }
    return 'Notification';
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      userId: userId,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

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
      createdAt = _parseApiDateTime(createdRaw);
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

    final titleRaw = _key(json, 'title', 'Title');
    final title = titleRaw is String ? titleRaw : '';

    return NotificationModel(
      notificationId: _key(json, 'notificationId', 'NotificationId') as int,
      userId: _key(json, 'userId', 'UserId') as int,
      title: title,
      message: (_key(json, 'message', 'Message') as String?) ?? '',
      createdAt: createdAt,
      isRead: isRead,
    );
  }
}

/// If the server sends an ISO-8601 instant without a timezone, Dart may parse
/// it as *local* wall time and skip [toLocal], which looks "wrong" (often ~UTC offset).
/// API timestamps for notifications are UTC; treat offset-less ISO strings as UTC.
DateTime? _parseApiDateTime(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  if (t.endsWith('Z')) return DateTime.tryParse(t);
  // e.g. ...+02:00 or ...-05:00
  if (RegExp(r'[+-]\d{2}:\d{2}$').hasMatch(t)) {
    return DateTime.tryParse(t);
  }
  if (t.contains('T') && t.length > 10) {
    return DateTime.tryParse('${t}Z') ?? DateTime.tryParse(t);
  }
  return DateTime.tryParse(t);
}

/// Formats [DateTime] from the API (usually UTC) for local display.
DateTime notificationDisplayTime(DateTime t) => t.isUtc ? t.toLocal() : t;

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

