import 'package:flutter/material.dart';

import '../models/yacht_calendar_block.dart';
import '../models/yacht_availability.dart';
import '../models/reservation.dart';

/// Shared rules for yacht date availability in calendars.
class YachtAvailabilityCalendar {
  YachtAvailabilityCalendar._();

  static bool reservationBlocksAvailability(Reservation r) {
    final s = (r.status ?? '').toLowerCase();
    return s != 'cancelled' && s != 'completed';
  }

  /// True when [day] (date only) overlaps a block or blocking reservation/availability row.
  static bool isDayUnavailable(
    DateTime day, {
    List<YachtCalendarBlock> calendarBlocks = const [],
    List<Reservation> reservations = const [],
    List<YachtAvailability> ownerBlocks = const [],
    int? excludeReservationId,
  }) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    for (final b in calendarBlocks) {
      if (_overlapsDay(dayStart, dayEnd, b.startDate, b.endDate)) return true;
    }

    for (final a in ownerBlocks.where((x) => x.isBlocked)) {
      if (_overlapsDay(dayStart, dayEnd, a.startDate, a.endDate)) return true;
    }

    for (final r in reservations.where(reservationBlocksAvailability)) {
      if (excludeReservationId != null && r.reservationId == excludeReservationId) {
        continue;
      }
      if (_overlapsDay(dayStart, dayEnd, r.startDate, r.endDate)) return true;
    }

    return false;
  }

  static bool rangeHasUnavailableDay(
    DateTimeRange range, {
    List<YachtCalendarBlock> calendarBlocks = const [],
    List<Reservation> reservations = const [],
    List<YachtAvailability> ownerBlocks = const [],
    int? excludeReservationId,
  }) {
    var d = DateTime(range.start.year, range.start.month, range.start.day);
    final end = DateTime(range.end.year, range.end.month, range.end.day);
    while (!d.isAfter(end)) {
      if (isDayUnavailable(
        d,
        calendarBlocks: calendarBlocks,
        reservations: reservations,
        ownerBlocks: ownerBlocks,
        excludeReservationId: excludeReservationId,
      )) {
        return true;
      }
      d = d.add(const Duration(days: 1));
    }
    return false;
  }

  static bool _overlapsDay(
    DateTime dayStart,
    DateTime dayEnd,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    return dayStart.isBefore(periodEnd) && dayEnd.isAfter(periodStart);
  }
}
