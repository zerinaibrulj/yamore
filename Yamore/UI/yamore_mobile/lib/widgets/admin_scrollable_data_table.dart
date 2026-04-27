import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

/// Desktop-friendly wrapper for wide [DataTable]s: horizontal + vertical scrolling
/// with [ScrollController]s wired to [Scrollbar]s (required for working thumbs on Windows).
///
/// Uses [LayoutBuilder] so minimum width matches the **actual** area (not full-screen
/// [MediaQuery]), and tightens [DataTableTheme] when the window is narrow.
class AdminScrollableDataTable extends StatefulWidget {
  const AdminScrollableDataTable({
    super.key,
    required this.child,
    this.minContentWidth = 1100,
  });

  final Widget child;
  final double minContentWidth;

  @override
  State<AdminScrollableDataTable> createState() => _AdminScrollableDataTableState();
}

class _AdminScrollableDataTableState extends State<AdminScrollableDataTable> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        if (!viewportW.isFinite || viewportW <= 0) {
          return const SizedBox.shrink();
        }

        final minW = math.max(viewportW, widget.minContentWidth);
        final tight = viewportW < 1180;

        final themed = Theme(
          data: Theme.of(context).copyWith(
            dataTableTheme: DataTableThemeData(
              headingRowHeight: tight ? 44 : 52,
              dataRowMinHeight: tight ? 40 : 48,
              dataRowMaxHeight: tight ? 52 : 64,
              columnSpacing: tight ? 12 : 20,
              horizontalMargin: tight ? 12 : 20,
            ),
          ),
          child: widget.child,
        );

        return ScrollConfiguration(
          behavior: const AdminDesktopScrollBehavior(),
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            interactive: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              primary: false,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: minW),
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  interactive: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    scrollDirection: Axis.vertical,
                    primary: false,
                    child: themed,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Allows dragging scrollables with the mouse / trackpad on desktop (not only touch).
class AdminDesktopScrollBehavior extends MaterialScrollBehavior {
  const AdminDesktopScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
