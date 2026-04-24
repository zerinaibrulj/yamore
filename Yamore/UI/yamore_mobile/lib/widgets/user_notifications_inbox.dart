import 'dart:async';

import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../theme/app_theme.dart';

class UserNotificationsInbox extends StatefulWidget {
  final bool loading;
  final String? error;
  final List<NotificationModel> notifications;
  final String Function(DateTime) formatDateTime;
  final Future<void> Function(NotificationModel) onMarkRead;
  /// If set, only this row shows a small progress indicator while [onMarkRead] runs.
  final int? markingNotificationId;
  /// Total number of notifications on the server (all pages), for the summary line.
  final int? totalCount;
  /// True when more pages are available to load.
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback? onLoadMore;
  /// Viewport height for the scrollable feed (infinite scroll triggers near the bottom of this view).
  final double listMaxHeight;

  const UserNotificationsInbox({
    super.key,
    required this.loading,
    required this.error,
    required this.notifications,
    required this.formatDateTime,
    required this.onMarkRead,
    this.markingNotificationId,
    this.totalCount,
    this.hasMore = false,
    this.loadingMore = false,
    this.onLoadMore,
    this.listMaxHeight = 360,
  });

  @override
  State<UserNotificationsInbox> createState() => _UserNotificationsInboxState();
}

class _UserNotificationsInboxState extends State<UserNotificationsInbox> {
  late final ScrollController _listScroll = ScrollController();
  Timer? _infiniteDebounce;
  static const _infiniteDebounceMs = 400;
  static const _loadWhenWithinPx = 100.0;
  var _infiniteCooldown = false;
  /// If true, the feed is shorter than the viewport — show a [Load more] CTA; otherwise rely on near-end scroll.
  bool _showLoadMoreCta = false;
  Timer? _infiniteUnblock;

  @override
  void initState() {
    super.initState();
    _listScroll.addListener(_onInboxListScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeLoadMoreCta());
  }

  void _onInboxListScroll() {
    _onListScroll();
    _recomputeLoadMoreCta();
  }

  @override
  void didUpdateWidget(UserNotificationsInbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadingMore && !widget.loadingMore) {
      _infiniteUnblock?.cancel();
      // Avoid chaining multiple loads while the scroll view stays at the same bottom position.
      _infiniteCooldown = true;
      _infiniteUnblock = Timer(
        const Duration(milliseconds: 500),
        () {
          if (mounted) {
            setState(() => _infiniteCooldown = false);
          }
        },
      );
    }
    if (oldWidget.hasMore && !widget.hasMore) {
      _infiniteCooldown = false;
    }
    if (oldWidget.notifications.length != widget.notifications.length ||
        oldWidget.hasMore != widget.hasMore ||
        oldWidget.loading != widget.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recomputeLoadMoreCta());
    }
  }

  void _recomputeLoadMoreCta() {
    if (!mounted) return;
    if (!_listScroll.hasClients) {
      if (_showLoadMoreCta) {
        setState(() => _showLoadMoreCta = false);
      }
      return;
    }
    final shortList =
        _listScroll.position.maxScrollExtent < 8.0; // not scrollable
    final show = shortList && widget.hasMore && !widget.loading && !widget.loadingMore;
    if (show != _showLoadMoreCta) {
      setState(() => _showLoadMoreCta = show);
    }
  }

  void _onListScroll() {
    if (widget.onLoadMore == null ||
        !widget.hasMore ||
        widget.loadingMore ||
        widget.loading ||
        _infiniteCooldown) {
      return;
    }
    if (!_listScroll.hasClients) return;
    final p = _listScroll.position;
    if (p.maxScrollExtent > 4 &&
        p.pixels >= p.maxScrollExtent - _loadWhenWithinPx) {
      _infiniteDebounce?.cancel();
      _infiniteDebounce = Timer(
        const Duration(milliseconds: _infiniteDebounceMs),
        () {
          if (!mounted) return;
          if (widget.onLoadMore == null ||
              !widget.hasMore ||
              widget.loadingMore) {
            return;
          }
          widget.onLoadMore!();
        },
      );
    }
  }

  @override
  void dispose() {
    _infiniteDebounce?.cancel();
    _infiniteUnblock?.cancel();
    _listScroll
      ..removeListener(_onInboxListScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (widget.error != null) {
      return Text(
        'Failed to load notifications: ${widget.error}',
        style: TextStyle(color: Colors.red.shade700, fontSize: 12),
      );
    }
    if (widget.notifications.isEmpty) {
      return const Text('No notifications yet.');
    }

    final totalForSummary = widget.totalCount ?? widget.notifications.length;
    final unread = widget.notifications.where((n) => n.isRead != true).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (unread > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              '$unread unread of $totalForSummary',
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
              totalForSummary == 1
                  ? '1 notification (all read)'
                  : '$totalForSummary notifications (all read)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        const SizedBox(height: 6),
        SizedBox(
          height: widget.listMaxHeight,
          child: ListView.separated(
            primary: false,
            controller: _listScroll,
            itemCount: widget.notifications.length,
            padding: EdgeInsets.zero,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _itemTile(widget.notifications[i]),
          ),
        ),
        if (widget.loadingMore) ...[
          const SizedBox(height: 10),
          const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ],
        if (widget.onLoadMore != null &&
            widget.hasMore &&
            !widget.loading &&
            !widget.loadingMore &&
            _showLoadMoreCta) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: widget.onLoadMore,
              icon: const Icon(Icons.expand_more, size: 20),
              label: const Text('Load more'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _itemTile(NotificationModel n) {
    final read = n.isRead == true;
    return Material(
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
                widget.formatDateTime(n.createdAt!),
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
            : widget.markingNotificationId == n.notificationId
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    onPressed: () => widget.onMarkRead(n),
                    child: const Text('Read'),
                  ),
      ),
    );
  }
}
