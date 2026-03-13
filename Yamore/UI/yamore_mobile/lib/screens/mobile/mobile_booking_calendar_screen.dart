import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/yacht_overview.dart';
import '../../models/reservation.dart';
import '../../models/yacht_availability.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'mobile_booking_options_screen.dart';

class MobileBookingCalendarScreen extends StatefulWidget {
  final ApiService api;
  final AppUser user;
  final YachtOverview overview;

  const MobileBookingCalendarScreen({
    super.key,
    required this.api,
    required this.user,
    required this.overview,
  });

  @override
  State<MobileBookingCalendarScreen> createState() =>
      _MobileBookingCalendarScreenState();
}

class _MobileBookingCalendarScreenState
    extends State<MobileBookingCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _selectedStart;

  bool _loading = true;
  String? _error;

  List<Reservation> _reservations = [];
  List<YachtAvailability> _blocks = [];

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
      ];

  bool _slotAvailable(DateTime start, Duration baseDuration) {
    final end = start.add(baseDuration);
    // Blocked periods
    for (final a in _blocks.where((b) => b.isBlocked)) {
      if (start.isBefore(a.endDate) && end.isAfter(a.startDate)) {
        return false;
      }
    }
    // Existing reservations (not cancelled)
    for (final r in _reservations.where(
        (r) => (r.status ?? '').toLowerCase() != 'cancelled')) {
      if (start.isBefore(r.endDate) && end.isAfter(r.startDate)) {
        return false;
      }
    }
    return true;
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
                            _buildCalendar(),
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
              onPressed: _selectedStart == null ? null : _goNext,
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

  Widget _buildCalendar() {
    final firstDate = DateTime.now();
    final lastDate = firstDate.add(const Duration(days: 365));
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: CalendarDatePicker(
          initialDate: _selectedDay ?? _focusedDay,
          firstDate: firstDate,
          lastDate: lastDate,
          onDateChanged: (date) {
            setState(() {
              _selectedDay = date;
              _selectedStart = null;
            });
          },
          currentDate: DateTime.now(),
        ),
      ),
    );
  }

  Widget _buildTimes() {
    if (_selectedDay == null) {
      return const Text(
        'Select a date to see available times.',
        style: TextStyle(fontSize: 13),
      );
    }
    final baseDuration = const Duration(hours: 4);
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
            final start = DateTime(_selectedDay!.year, _selectedDay!.month,
                _selectedDay!.day, t.hour, t.minute);
            final available = _slotAvailable(start, baseDuration);
            final selected = _selectedStart != null &&
                _selectedStart!.year == start.year &&
                _selectedStart!.month == start.month &&
                _selectedStart!.day == start.day &&
                _selectedStart!.hour == start.hour &&
                _selectedStart!.minute == start.minute;
            return ChoiceChip(
              label: Text(
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}h',
              ),
              selected: selected,
              onSelected:
                  available ? (_) => setState(() => _selectedStart = start) : null,
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

  void _goNext() {
    if (_selectedStart == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileBookingOptionsScreen(
          api: widget.api,
          user: widget.user,
          overview: widget.overview,
          startDateTime: _selectedStart!,
        ),
      ),
    );
  }
}

