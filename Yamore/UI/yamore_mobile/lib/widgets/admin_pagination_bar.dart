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

  /// Desktop-style footer row (e.g. admin).
  static const _rowFont = TextStyle(
    fontSize: 10.5,
    height: 1.2,
    letterSpacing: 0.15,
  );
  static const _rowSubFont = TextStyle(
    fontSize: 10.5,
    height: 1.2,
    letterSpacing: 0.15,
    color: Color(0x8A000000),
  );

  /// Mobile News stacked layout — smaller than the row layout.
  static const _stackFont = TextStyle(
    fontSize: 10.0,
    height: 1.25,
    letterSpacing: 0.1,
  );
  static const _stackMuted = TextStyle(
    fontSize: 9.5,
    height: 1.25,
    letterSpacing: 0.1,
    color: Color(0x8A000000),
  );

  Widget _navButtonsImpl(int totalPages, {required bool compact}) {
    final s = compact ? 18.0 : 20.0;
    final box = compact ? 32.0 : 36.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            minimumSize: Size(box, box),
            padding: const EdgeInsets.all(4),
          ),
          icon: Icon(Icons.chevron_left, size: s),
          onPressed: !loading && currentPage > 0 ? onPrevious : null,
        ),
        const SizedBox(width: 2),
        IconButton.filledTonal(
          style: IconButton.styleFrom(
            visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
            minimumSize: Size(box, box),
            padding: const EdgeInsets.all(4),
          ),
          icon: Icon(Icons.chevron_right, size: s),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                  const Icon(Icons.info_outline, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'Showing $start–$end of $total',
                    style: _rowFont,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Page ${currentPage + 1} of $totalPages',
                    style: _rowSubFont,
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    'Rows per page: $pageSize',
                    style: _rowFont,
                  ),
                  const SizedBox(width: 10),
                  _navButtonsImpl(totalPages, compact: false),
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
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
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(Icons.info_outline, size: 14),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        style: _stackFont,
                        children: [
                          const TextSpan(text: 'Showing '),
                          TextSpan(
                            text: '$start–$end',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(text: ' of $total  ·  '),
                          TextSpan(
                            text: 'Page ${currentPage + 1} of $totalPages',
                            style: _stackMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Rows per page: $pageSize',
                    style: _stackMuted,
                  ),
                  _navButtonsImpl(totalPages, compact: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
