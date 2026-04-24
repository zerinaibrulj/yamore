import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../theme/app_theme.dart';

class UserNotificationsInbox extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<NotificationModel> notifications;
  final String Function(DateTime) formatDateTime;
  final Future<void> Function(NotificationModel) onMarkRead;
  /// If set, only this row shows a small progress indicator while [onMarkRead] runs.
  final int? markingNotificationId;

  const UserNotificationsInbox({
    super.key,
    required this.loading,
    required this.error,
    required this.notifications,
    required this.formatDateTime,
    required this.onMarkRead,
    this.markingNotificationId,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (error != null) {
      return Text(
        'Failed to load notifications: $error',
        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
      );
    }
    if (notifications.isEmpty) {
      return const Text('No notifications yet.');
    }
    final unread = notifications.where((n) => n.isRead != true).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (unread > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '$unread unread of ${notifications.length}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '${notifications.length} notification${notifications.length == 1 ? '' : 's'} (all read)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        const SizedBox(height: 6),
        ...notifications.map(
          (n) {
            final read = n.isRead == true;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: read
                    ? Colors.transparent
                    : AppTheme.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  leading: Icon(
                    read
                        ? Icons.notifications_none_outlined
                        : Icons.notifications_active_outlined,
                    color: AppTheme.primaryBlue,
                  ),
                  title: Text(
                    n.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: read ? FontWeight.w500 : FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (n.message.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          n.message,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                      if (n.createdAt != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          formatDateTime(n.createdAt!),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  isThreeLine: n.message.trim().isNotEmpty,
                  trailing: read
                      ? null
                      : markingNotificationId == n.notificationId
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: () => onMarkRead(n),
                              child: const Text('Read'),
                            ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
