import 'package:flutter/material.dart';

/// Same layout as the News / Users / Yachts admin lists: “Showing a–b of n”,
/// page indicator, “Rows per page: k”, and tonal chevrons.
class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({
    super.key,
    required this.total,
    required this.currentPage,
    required this.pageSize,
    required this.itemsOnPage,
    required this.loading,
    this.onPrevious,
    this.onNext,
  });

  final int total;
  /// 0-based page index.
  final int currentPage;
  final int pageSize;
  final int itemsOnPage;
  final bool loading;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) {
      return const SizedBox.shrink();
    }
    final start = currentPage * pageSize + 1;
    final end = (currentPage * pageSize + itemsOnPage).clamp(0, total);
    final totalPages = (total + pageSize - 1) ~/ pageSize;
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Showing $start–$end of $total',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (total > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Page ${currentPage + 1} of $totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    'Rows per page: $pageSize',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.chevron_left),
                    onPressed: !loading && currentPage > 0 ? onPrevious : null,
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.chevron_right),
                    onPressed: !loading && (currentPage + 1) < totalPages
                        ? onNext
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
