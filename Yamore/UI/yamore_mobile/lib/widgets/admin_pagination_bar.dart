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
    // Stacked layout avoids a single wide Row (overflow on narrow phones, e.g. News & notices).
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.info_outline, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Showing $start–$end of $total  •  Page ${currentPage + 1} of $totalPages',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rows per page: $pageSize',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(40, 40),
                          padding: const EdgeInsets.all(6),
                        ),
                        icon: const Icon(Icons.chevron_left, size: 22),
                        onPressed: !loading && currentPage > 0 ? onPrevious : null,
                      ),
                      const SizedBox(width: 2),
                      IconButton.filledTonal(
                        style: IconButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          minimumSize: const Size(40, 40),
                          padding: const EdgeInsets.all(6),
                        ),
                        icon: const Icon(Icons.chevron_right, size: 22),
                        onPressed: !loading && (currentPage + 1) < totalPages
                            ? onNext
                            : null,
                      ),
                    ],
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
