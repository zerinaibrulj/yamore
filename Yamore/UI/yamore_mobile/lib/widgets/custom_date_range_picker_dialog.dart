import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable date range picker dialog with a clean header and formatted month/year.
/// Use via: showDialog<DateTimeRange>(..., builder: (ctx) => CustomDateRangePickerDialog(...))
class CustomDateRangePickerDialog extends StatefulWidget {
  final DateTimeRange initialRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const CustomDateRangePickerDialog({
    super.key,
    required this.initialRange,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<CustomDateRangePickerDialog> createState() =>
      _CustomDateRangePickerDialogState();
}

class _CustomDateRangePickerDialogState extends State<CustomDateRangePickerDialog> {
  static const List<String> _weekdays = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'
  ];
  static const List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late DateTime? _rangeStart;
  late DateTime? _rangeEnd;
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _rangeStart = DateTime(
      widget.initialRange.start.year,
      widget.initialRange.start.month,
      widget.initialRange.start.day,
    );
    _rangeEnd = DateTime(
      widget.initialRange.end.year,
      widget.initialRange.end.month,
      widget.initialRange.end.day,
    );
    _viewMonth = DateTime(_rangeStart!.year, _rangeStart!.month);
  }

  void _onDayTap(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final first = DateTime(
        widget.firstDate.year, widget.firstDate.month, widget.firstDate.day);
    final last = DateTime(
        widget.lastDate.year, widget.lastDate.month, widget.lastDate.day);
    if (d.isBefore(first) || d.isAfter(last)) return;
    setState(() {
      if (_rangeStart == null || (_rangeStart != null && _rangeEnd != null)) {
        _rangeStart = d;
        _rangeEnd = null;
      } else if (d.isBefore(_rangeStart!) || d.isAtSameMomentAs(_rangeStart!)) {
        _rangeStart = d;
        _rangeEnd = null;
      } else {
        _rangeEnd = d;
      }
    });
  }

  bool _isInRange(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    if (_rangeStart == null) return false;
    if (_rangeEnd == null) return d.isAtSameMomentAs(_rangeStart!);
    final start =
        DateTime(_rangeStart!.year, _rangeStart!.month, _rangeStart!.day);
    final end = DateTime(_rangeEnd!.year, _rangeEnd!.month, _rangeEnd!.day);
    return !d.isBefore(start) && !d.isAfter(end);
  }

  bool _isRangeStart(DateTime day) {
    if (_rangeStart == null) return false;
    return day.year == _rangeStart!.year &&
        day.month == _rangeStart!.month &&
        day.day == _rangeStart!.day;
  }

  bool _isRangeEnd(DateTime day) {
    if (_rangeEnd == null) return false;
    return day.year == _rangeEnd!.year &&
        day.month == _rangeEnd!.month &&
        day.day == _rangeEnd!.day;
  }

  String get _formattedRange {
    if (_rangeStart == null) return 'Select dates';
    final s = _rangeStart!;
    if (_rangeEnd == null) {
      return '${_monthNames[s.month - 1]} ${s.day}, ${s.year}';
    }
    final e = _rangeEnd!;
    if (s.month == e.month && s.year == e.year) {
      return '${_monthNames[s.month - 1]} ${s.day} – ${e.day}, ${s.year}';
    }
    return '${s.day} ${_monthNames[s.month - 1]} – ${e.day} ${_monthNames[e.month - 1]} ${s.year}';
  }

  @override
  Widget build(BuildContext context) {
    final year = _viewMonth.year;
    final month = _viewMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDay.weekday;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

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
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.white, size: 22),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Select travel dates',
                      style: TextStyle(
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
                    onPressed: () {
                      if (_rangeStart != null && _rangeEnd != null) {
                        Navigator.of(context).pop(DateTimeRange(
                          start: _rangeStart!,
                          end: _rangeEnd!,
                        ));
                      } else if (_rangeStart != null) {
                        Navigator.of(context).pop(DateTimeRange(
                          start: _rangeStart!,
                          end: _rangeStart!,
                        ));
                      }
                    },
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
                _formattedRange,
                style: TextStyle(
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
                    onPressed: DateTime(year, month - 1, 1).isBefore(DateTime(
                            widget.firstDate.year,
                            widget.firstDate.month,
                            1))
                        ? null
                        : () {
                            setState(() {
                              _viewMonth = DateTime(year, month - 1);
                            });
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
                    onPressed: DateTime(year, month + 1, 1).isAfter(DateTime(
                            widget.lastDate.year,
                            widget.lastDate.month,
                            1))
                        ? null
                        : () {
                            setState(() {
                              _viewMonth = DateTime(year, month + 1);
                            });
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
                  // Same column width for weekday labels and day cells (no fixed 7×40
                  // grid centered under a full-width Expanded row — that caused misalignment).
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
                              final isPast = date.isBefore(today);
                              final inRange = _isInRange(date);
                              final isStart = _isRangeStart(date);
                              final isEnd = _isRangeEnd(date);
                              final canTap = !isPast;

                              return SizedBox(
                                width: cellW,
                                height: cellH,
                                child: Padding(
                                  padding: const EdgeInsets.all(2),
                                  child: Material(
                                    color: isPast
                                        ? Colors.grey.shade100
                                        : inRange
                                            ? (isStart || isEnd
                                                ? AppTheme.primaryBlue
                                                : AppTheme.primaryBlue
                                                    .withOpacity(0.14))
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
                                            color: isPast
                                                ? Colors.grey
                                                : (isStart || isEnd)
                                                    ? Colors.white
                                                    : inRange
                                                        ? AppTheme.primaryBlue
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
