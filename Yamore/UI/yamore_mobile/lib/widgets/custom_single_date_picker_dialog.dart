import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Single-day picker with the same look as [CustomDateRangePickerDialog] / booking flow.
///
/// Returns the selected calendar [DateTime] (date-only; time is not set) when the user
/// taps **Save**, or `null` if dismissed.
class CustomSingleDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final String title;

  const CustomSingleDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.title = 'Select forecast date',
  });

  @override
  State<CustomSingleDatePickerDialog> createState() =>
      _CustomSingleDatePickerDialogState();
}

class _CustomSingleDatePickerDialogState
    extends State<CustomSingleDatePickerDialog> {
  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late DateTime _selected;
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _selected = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
    );
    _viewMonth = DateTime(_selected.year, _selected.month);
  }

  void _onDayTap(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final first = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final last = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );
    if (d.isBefore(first) || d.isAfter(last)) return;
    setState(() => _selected = d);
  }

  bool _isSelected(DateTime day) {
    return day.year == _selected.year &&
        day.month == _selected.month &&
        day.day == _selected.day;
  }

  String get _formattedSelection {
    final s = _selected;
    return '${_monthNames[s.month - 1]} ${s.day}, ${s.year}';
  }

  @override
  Widget build(BuildContext context) {
    final year = _viewMonth.year;
    final month = _viewMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDay.weekday;
    final rangeFirst = DateTime(
      widget.firstDate.year,
      widget.firstDate.month,
      widget.firstDate.day,
    );
    final rangeLast = DateTime(
      widget.lastDate.year,
      widget.lastDate.month,
      widget.lastDate.day,
    );

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 520),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 14, 12, 12),
              decoration: const BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.18),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(_selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(
                _formattedSelection,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: AppTheme.primaryBlue,
                    ),
                    icon: const Icon(Icons.chevron_left),
                    onPressed: DateTime(year, month - 1, 1).isBefore(
                      DateTime(widget.firstDate.year, widget.firstDate.month, 1),
                    )
                        ? null
                        : () {
                            setState(
                              () => _viewMonth = DateTime(year, month - 1),
                            );
                          },
                  ),
                  Text(
                    '${_monthNames[month - 1]} $year',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  IconButton.filled(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: AppTheme.primaryBlue,
                    ),
                    icon: const Icon(Icons.chevron_right),
                    onPressed: DateTime(year, month + 1, 1).isAfter(
                      DateTime(widget.lastDate.year, widget.lastDate.month, 1),
                    )
                        ? null
                        : () {
                            setState(
                              () => _viewMonth = DateTime(year, month + 1),
                            );
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cellW = constraints.maxWidth / 7;
                  final cellH = cellW.clamp(36.0, 46.0);
                  final leadingEmpty = firstWeekday - 1;
                  final totalCells = leadingEmpty + daysInMonth;
                  final rows = (totalCells / 7).ceil();

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: _weekdays.map((d) {
                          return SizedBox(
                            width: cellW,
                            child: Center(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      ...List.generate(rows, (row) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: List.generate(7, (col) {
                              final cellIndex = row * 7 + col;
                              if (cellIndex < leadingEmpty) {
                                return SizedBox(width: cellW, height: cellH);
                              }
                              final day = cellIndex - leadingEmpty + 1;
                              if (day > daysInMonth) {
                                return SizedBox(width: cellW, height: cellH);
                              }
                              final date = DateTime(year, month, day);
                              final outOfRange =
                                  date.isBefore(rangeFirst) || date.isAfter(rangeLast);
                              final selected = _isSelected(date);
                              final canTap = !outOfRange;

                              return SizedBox(
                                width: cellW,
                                height: cellH,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Material(
                                    color: outOfRange
                                        ? Colors.grey.shade100
                                        : selected
                                            ? AppTheme.primaryBlue
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    child: InkWell(
                                      onTap: canTap
                                          ? () => _onDayTap(date)
                                          : null,
                                      borderRadius: BorderRadius.circular(10),
                                      child: Center(
                                        child: Text(
                                          '$day',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: outOfRange
                                                ? Colors.grey
                                                : selected
                                                    ? Colors.white
                                                    : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
