import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/yacht_overview.dart';
import '../../models/reservation.dart';
import '../../models/yacht_availability.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_date_range_picker_dialog.dart';
import 'mobile_route_selection_screen.dart';

class MobileBookingCalendarScreen extends StatefulWidget {
  final ApiService api;
  final AppUser user;
  final AuthService authService;
  final YachtOverview overview;

  const MobileBookingCalendarScreen({
    super.key,
    required this.api,
    required this.user,
    required this.authService,
    required this.overview,
  });

  @override
  State<MobileBookingCalendarScreen> createState() =>
      _MobileBookingCalendarScreenState();
}

class _MobileBookingCalendarScreenState
    extends State<MobileBookingCalendarScreen> {
  DateTimeRange? _selectedRange;
  TimeOfDay? _selectedTime;

  bool _loading = true;
  String? _error;

  List<Reservation> _reservations = [];
  List<YachtAvailability> _blocks = [];

  DateTime _calendarMonth = DateTime.now();

  /// Matches server rules: past / cancelled / completed do not block new bookings.
  static bool _reservationBlocksAvailability(Reservation r) {
    final s = (r.status ?? '').toLowerCase();
    return s != 'cancelled' && s != 'completed';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.getReservations(
          page: 0,
          pageSize: 200,
          yachtId: widget.overview.yachtId,
        ),
        widget.api.getYachtAvailabilities(
          yachtId: widget.overview.yachtId,
          pageSize: 200,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _reservations = (results[0] as PagedReservations).resultList;
        _blocks = (results[1] as PagedYachtAvailabilities).resultList;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load availability: $e';
        _loading = false;
      });
    }
  }

  List<TimeOfDay> get _timeSlots => const [
        TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 10, minute: 0),
        TimeOfDay(hour: 12, minute: 0),
        TimeOfDay(hour: 15, minute: 0),
        TimeOfDay(hour: 18, minute: 0),
        TimeOfDay(hour: 20, minute: 0),
        TimeOfDay(hour: 22, minute: 0),
      ];

  bool _slotAvailable(DateTime start, DateTime end) {
    for (final a in _blocks.where((b) => b.isBlocked)) {
      if (start.isBefore(a.endDate) && end.isAfter(a.startDate)) {
        return false;
      }
    }
    for (final r in _reservations.where(_reservationBlocksAvailability)) {
      if (start.isBefore(r.endDate) && end.isAfter(r.startDate)) {
        return false;
      }
    }
    return true;
  }

  /// True if the given day (date only) is fully or partially booked (reservation or block overlaps it).
  bool _isDayBooked(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    for (final a in _blocks.where((b) => b.isBlocked)) {
      if (dayStart.isBefore(a.endDate) && dayEnd.isAfter(a.startDate)) return true;
    }
    for (final r in _reservations.where(_reservationBlocksAvailability)) {
      if (dayStart.isBefore(r.endDate) && dayEnd.isAfter(r.startDate)) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Choose Date & Time'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      color: AppTheme.primaryBlue,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        overview.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAvailabilityCalendar(),
                            const SizedBox(height: 20),
                            _buildDateRangeCard(),
                            const SizedBox(height: 16),
                            _buildTimes(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8BC34A),
              ),
              onPressed:
                  _selectedRange == null || _selectedTime == null ? null : _goNext,
              child: const Text(
                'NEXT STEP',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimes() {
    if (_selectedRange == null) {
      return const Text(
        'Select dates to see available times.',
        style: TextStyle(fontSize: 13),
      );
    }
    final days =
        _selectedRange!.end.difference(_selectedRange!.start).inDays.clamp(1, 365);
    final tripDuration = Duration(days: days);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available times',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _timeSlots.map((t) {
            final start = DateTime(
              _selectedRange!.start.year,
              _selectedRange!.start.month,
              _selectedRange!.start.day,
              t.hour,
              t.minute,
            );
            final end = start.add(tripDuration);
            final available = _slotAvailable(start, end);
            final selected = _selectedTime?.hour == t.hour &&
                _selectedTime?.minute == t.minute;
            return ChoiceChip(
              label: Text(
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}h',
              ),
              selected: selected,
              onSelected: available
                  ? (_) => setState(() => _selectedTime = t)
                  : null,
              labelStyle: TextStyle(
                color: available
                    ? (selected ? Colors.white : Colors.black87)
                    : Colors.grey.shade400,
              ),
              selectedColor: const Color(0xFF1a237e),
              disabledColor: Colors.grey.shade200,
            );
          }).toList(),
        ),
      ],
    );
  }

  static const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  Widget _buildAvailabilityCalendar() {
    final year = _calendarMonth.year;
    final month = _calendarMonth.month;
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    const double maxCellSize = 26;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: 18),
                const SizedBox(width: 6),
                const Text(
                  'Availability',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _calendarMonth = DateTime(year, month - 1)),
                  child: const Padding( padding: EdgeInsets.all(4), child: Icon(Icons.chevron_left, size: 20)),
                ),
                Text(
                  '${_monthName(month)} $year',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _calendarMonth = DateTime(year, month + 1)),
                  child: const Padding( padding: EdgeInsets.all(4), child: Icon(Icons.chevron_right, size: 20)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final cellSize =
                    ((constraints.maxWidth - 6) / 7).clamp(18.0, maxCellSize);
                final calendarWidth = cellSize * 7;

                final leadingEmpty = firstWeekday - 1;
                final totalCells = leadingEmpty + daysInMonth;
                final rows = (totalCells / 7).ceil();

                return Center(
                  child: SizedBox(
                    width: calendarWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: _weekdays.map((d) {
                            return SizedBox(
                              width: cellSize,
                              child: Center(
                                child: Text(
                                  d,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 2),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(rows, (row) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: List.generate(7, (col) {
                                  final cellIndex = row * 7 + col;
                                  if (cellIndex < leadingEmpty) {
                                    return SizedBox(
                                      width: cellSize,
                                      height: cellSize,
                                      child: const SizedBox(),
                                    );
                                  }
                                  final day = cellIndex - leadingEmpty + 1;
                                  if (day > daysInMonth) {
                                    return SizedBox(
                                      width: cellSize,
                                      height: cellSize,
                                      child: const SizedBox(),
                                    );
                                  }

                                  final date = DateTime(year, month, day);
                                  final isPast = date.isBefore(today);
                                  final booked = _isDayBooked(date);

                                  late final Color bg;
                                  late final Color fg;
                                  if (isPast) {
                                    bg = Colors.grey.shade200;
                                    fg = Colors.grey.shade500;
                                  } else if (booked) {
                                    bg = Colors.red.shade100;
                                    fg = Colors.red.shade800;
                                  } else {
                                    bg = Colors.green.shade50;
                                    fg = Colors.green.shade800;
                                  }

                                  return SizedBox(
                                    width: cellSize,
                                    height: cellSize,
                                    child: Padding(
                                      padding: const EdgeInsets.all(1),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius: BorderRadius.circular(4),
                                          border: Border.all(
                                            color: fg.withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$day',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: fg,
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
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.green.shade50, Colors.green.shade800, 'Available'),
                const SizedBox(width: 10),
                _legendDot(Colors.red.shade100, Colors.red.shade800, 'Booked'),
                const SizedBox(width: 10),
                _legendDot(Colors.grey.shade200, Colors.grey.shade500, 'Past'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color bg, Color fg, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(2), border: Border.all(color: fg.withOpacity(0.4), width: 0.5)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
      ],
    );
  }

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  Widget _buildDateRangeCard() {
    final now = DateTime.now();
    final initialRange = _selectedRange ??
        DateTimeRange(
          start: now.add(const Duration(days: 1)),
          end: now.add(const Duration(days: 4)),
        );
    final label = _selectedRange == null
        ? 'Select your travel dates'
        : '${_selectedRange!.start.day.toString().padLeft(2, '0')}.'
            '${_selectedRange!.start.month.toString().padLeft(2, '0')}.'
            '${_selectedRange!.start.year} – '
            '${_selectedRange!.end.day.toString().padLeft(2, '0')}.'
            '${_selectedRange!.end.month.toString().padLeft(2, '0')}.'
            '${_selectedRange!.end.year}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: ListTile(
        leading: const Icon(Icons.calendar_today_outlined),
        title: const Text(
          'Travel dates',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
        onTap: () async {
          final picked = await showDialog<DateTimeRange>(
            context: context,
            builder: (ctx) => CustomDateRangePickerDialog(
              initialRange: initialRange,
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            ),
          );
          if (picked != null) {
            setState(() {
              _selectedRange = picked;
              _selectedTime = null;
            });
          }
        },
      ),
    );
  }

  void _goNext() {
    if (_selectedRange == null || _selectedTime == null) return;
    final days =
        _selectedRange!.end.difference(_selectedRange!.start).inDays.clamp(1, 365);
    final start = DateTime(
      _selectedRange!.start.year,
      _selectedRange!.start.month,
      _selectedRange!.start.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final end = start.add(Duration(days: days));
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileRouteSelectionScreen(
          api: widget.api,
          user: widget.user,
          authService: widget.authService,
          overview: widget.overview,
          startDateTime: start,
          endDateTime: end,
        ),
      ),
    );
  }
}

