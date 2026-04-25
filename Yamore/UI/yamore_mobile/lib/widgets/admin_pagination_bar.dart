import 'package:flutter/material.dart';

/// Footer: “Showing a–b of n”, page indicator, “Rows per page: k”, tonal chevrons.
///
/// By default uses a **single row** (matches Users, Yachts, Services, etc.).
/// Set [narrowLayout] to true for the user/owner News tab on narrow phones where a
/// stacked two-row layout avoids horizontal overflow.
class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({
    super.key,
    required this.total,
    required this.currentPage,
    required this.pageSize,
    required this.itemsOnPage,
    required this.loading,
    this.narrowLayout = false,
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

  /// Stacked (two-row) info + rows/controls; avoids overflow in user News on small screens.
  final bool narrowLayout;

  @override
  Widget build(BuildContext context) {
    if (total <= 0) {
      return const SizedBox.shrink();
    }
    final start = currentPage * pageSize + 1;
    final end = (currentPage * pageSize + itemsOnPage).clamp(0, total);
    final totalPages = (total + pageSize - 1) ~/ pageSize;
    if (narrowLayout) {
      return _narrowStacked(
        start: start,
        end: end,
        totalPages: totalPages,
      );
    }
    return _adminRow(
      start: start,
      end: end,
      totalPages: totalPages,
    );
  }

  Widget _navButtons(int totalPages) {
    return Row(
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
          onPressed: !loading && (currentPage + 1) < totalPages ? onNext : null,
        ),
      ],
    );
  }

  Widget _adminRow({
    required int start,
    required int end,
    required int totalPages,
  }) {
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
                  const SizedBox(width: 8),
                  Text(
                    'Page ${currentPage + 1} of $totalPages',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Rows per page: $pageSize',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  _navButtons(totalPages),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _narrowStacked({
    required int start,
    required int end,
    required int totalPages,
  }) {
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
                  _navButtons(totalPages),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
