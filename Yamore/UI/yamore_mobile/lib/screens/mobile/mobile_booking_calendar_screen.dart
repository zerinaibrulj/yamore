import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/yacht_overview.dart';
import '../../models/reservation.dart';
import '../../models/yacht_availability.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'mobile_route_selection_screen.dart';

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
  DateTimeRange? _selectedRange;
  TimeOfDay? _selectedTime;

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
        TimeOfDay(hour: 18, minute: 0),
        TimeOfDay(hour: 20, minute: 0),
        TimeOfDay(hour: 22, minute: 0),
      ];

  bool _slotAvailable(DateTime start, DateTime end) {
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
          final picked = await showDateRangePicker(
            context: context,
            firstDate: now,
            lastDate: now.add(const Duration(days: 365)),
            initialDateRange: initialRange,
            helpText: 'Select travel dates',
            confirmText: 'Save',
            cancelText: 'Cancel',
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                        primary: AppTheme.primaryBlue,
                      ),
                  dialogTheme: const DialogThemeData(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxWidth: 420, maxHeight: 520),
                    child: child!,
                  ),
                ),
              );
            },
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
          overview: widget.overview,
          startDateTime: start,
          endDateTime: end,
        ),
      ),
    );
  }
}

