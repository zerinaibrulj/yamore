import 'package:flutter/material.dart';

import '../../models/city.dart';
import '../../models/reservation.dart';
import '../../models/route.dart';
import '../../models/user.dart';
import '../../models/weather_forecast.dart';
import '../../models/yacht_detail.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class MobileBookingsTab extends StatefulWidget {
  final AuthService authService;
  final AppUser user;

  const MobileBookingsTab({
    super.key,
    required this.authService,
    required this.user,
  });

  @override
  State<MobileBookingsTab> createState() => _MobileBookingsTabState();
}

class _MobileBookingsTabState extends State<MobileBookingsTab> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  bool _loading = true;
  String? _error;
  int _tabIndex = 0; // 0 = active, 1 = past

  List<Reservation> _allReservations = [];
  final Map<int, YachtDetail> _yachtCache = {};
  final Map<int, List<RouteModel>> _routesByYachtId = {};
  final List<CityModel> _cities = [];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getReservations(
        page: 0,
        pageSize: 100,
        userId: widget.user.userId,
      );
      final list = result.resultList;
      final yachtIds = list.map((r) => r.yachtId).toSet().toList();
      List<CityModel> cities = [];
      try {
        cities = await _api.getCities();
      } catch (_) {}
      final details = await Future.wait(
        yachtIds.map((id) async {
          try {
            final d = await _api.getYachtById(id);
            return MapEntry(id, d);
          } catch (_) {
            return MapEntry<int, YachtDetail?>(id, null);
          }
        }),
      );
      for (final entry in details) {
        if (entry.value != null) {
          _yachtCache[entry.key] = entry.value!;
        }
      }
      final routes = await Future.wait(
        yachtIds.map((id) async {
          try {
            final r = await _api.getRoutesForYacht(id);
            return MapEntry(id, r);
          } catch (_) {
            return MapEntry<int, List<RouteModel>>(id, const []);
          }
        }),
      );
      for (final entry in routes) {
        _routesByYachtId[entry.key] = entry.value;
      }
      _cities
        ..clear()
        ..addAll(cities);
      if (!mounted) return;
      setState(() {
        _allReservations = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load reservations: $e';
        _loading = false;
      });
    }
  }

  List<Reservation> get _activeReservations {
    final now = DateTime.now();
    return _allReservations.where((r) {
      final status = (r.status ?? '').toLowerCase();
      return status != 'cancelled' && r.endDate.isAfter(now);
    }).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  List<Reservation> get _pastReservations {
    final now = DateTime.now();
    return _allReservations.where((r) {
      final status = (r.status ?? '').toLowerCase();
      return status == 'cancelled' || !r.endDate.isAfter(now);
    }).toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _loadReservations,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red.shade600),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadReservations,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              _buildList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'My Bookings',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _segmentButton('ACTIVE', 0),
              const SizedBox(width: 8),
              _segmentButton('PAST', 1),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segmentButton(String label, int index) {
    final selected = _tabIndex == index;
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor:
              selected ? AppTheme.primaryBlue : Colors.white,
          foregroundColor:
              selected ? Colors.white : Colors.black87,
          side: BorderSide(
              color: selected
                  ? AppTheme.primaryBlue
                  : Colors.grey.shade300),
        ),
        onPressed: () => setState(() => _tabIndex = index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final list =
        _tabIndex == 0 ? _activeReservations : _pastReservations;
    if (list.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Text(
            'No reservations in this section yet.',
            style: TextStyle(fontSize: 14),
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final r = list[index];
            final yacht = _yachtCache[r.yachtId];
            return _reservationCard(r, yacht);
          },
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _reservationCard(Reservation r, YachtDetail? yacht) {
    final start = r.startDate;
    final end = r.endDate;
    final isActive = _activeReservations.contains(r);
    final status = (r.status ?? 'Pending');
    final isConfirmed = status.toLowerCase() == 'confirmed';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    yacht?.name ?? 'Unknown yacht',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                if (isConfirmed)
                  OutlinedButton.icon(
                    onPressed: () => _showWeatherForReservation(r),
                    icon: const Icon(Icons.cloud_outlined, size: 18),
                    label: const Text('Weather'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      side: BorderSide(color: Colors.blue.shade200),
                      foregroundColor: Colors.blue.shade700,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${start.day.toString().padLeft(2, '0')}.'
              '${start.month.toString().padLeft(2, '0')}.'
              '${start.year} – '
              '${end.day.toString().padLeft(2, '0')}.'
              '${end.month.toString().padLeft(2, '0')}.'
              '${end.year}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            if (r.totalPrice != null)
              Text(
                'Total price: €${r.totalPrice!.toStringAsFixed(0)}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.shade50
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isActive
                          ? Colors.green.shade700
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (isActive)
                        TextButton(
                          onPressed: () => _confirmCancel(r),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          child: Text(
                            'Cancel reservation',
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _routeLabel(RouteModel route) {
    final startCity = _cities
        .firstWhere((c) => c.cityId == route.startCityId, orElse: () => CityModel.empty());
    final endCity = _cities
        .firstWhere((c) => c.cityId == route.endCityId, orElse: () => CityModel.empty());
    if (startCity.cityId != -1 && endCity.cityId != -1) {
      return '${startCity.name} → ${endCity.name}';
    }
    if (route.description != null && route.description!.trim().isNotEmpty) {
      return route.description!.trim();
    }
    return 'Selected route';
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}h';

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  List<WeatherForecastModel> _forecastsForReservationDates(
    Iterable<WeatherForecastModel> forecasts,
    DateTime startDate,
    DateTime endDate,
  ) {
    var from = _dateOnly(startDate);
    var to = _dateOnly(endDate);
    if (to.isBefore(from)) {
      final temp = from;
      from = to;
      to = temp;
    }

    final filtered = forecasts.where((f) {
      final d = f.forecastDate;
      if (d == null) return false;
      final day = _dateOnly(d);
      return !day.isBefore(from) && !day.isAfter(to);
    }).toList();

    filtered.sort((a, b) {
      final da = a.forecastDate;
      final db = b.forecastDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return filtered;
  }

  Future<void> _showWeatherForReservation(Reservation r) async {
    List<RouteModel> routes = const <RouteModel>[];
    try {
      // Refresh routes live in case admin added/edited routes after this tab was loaded.
      routes = await _api.getRoutesForYacht(r.yachtId);
      _routesByYachtId[r.yachtId] = routes;
    } catch (_) {
      routes = _routesByYachtId[r.yachtId] ?? const <RouteModel>[];
    }
    if (routes.isEmpty) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Weather'),
          content: const Text('Weather forecast is not available for this yacht yet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            )
          ],
        ),
      );
      return;
    }

    try {
      final weatherByRoute = <MapEntry<RouteModel, List<WeatherForecastModel>>>[];
      for (final route in routes) {
        // Load all forecasts for the route, then keep all entries that match
        // reservation calendar dates (inclusive), regardless of forecast time.
        final allRouteForecasts = await _api.getWeatherForRoute(route.routeId);
        final matchingDates = _forecastsForReservationDates(
          allRouteForecasts,
          r.startDate,
          r.endDate,
        );
        if (matchingDates.isNotEmpty) {
          weatherByRoute.add(MapEntry(route, matchingDates));
        }
      }

      if (!mounted) return;
      if (weatherByRoute.isEmpty) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Weather'),
            content: const Text(
              'Weather forecast is not available yet for this reservation.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              )
            ],
          ),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Weather forecast'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...weatherByRoute.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Route: ${_routeLabel(entry.key)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ...entry.value.map(
                            (f) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (f.forecastDate != null)
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.calendar_today_outlined, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Date & time: ${_formatDateTime(f.forecastDate!)}',
                                              ),
                                            ),
                                          ],
                                        ),
                                      if (f.windSpeed != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.air, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text('Wind: ${f.windSpeed} km/h'),
                                            ),
                                          ],
                                        ),
                                      if (f.temperature != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.thermostat, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text('Temperature: ${f.temperature}°C'),
                                            ),
                                          ],
                                        ),
                                      if (f.condition != null)
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.wb_sunny_outlined, size: 16),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text('Condition: ${f.condition}'),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load weather: $e')),
      );
    }
  }

  Future<void> _confirmCancel(Reservation r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel reservation?'),
        content: const Text(
          'Are you sure you want to cancel this reservation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.cancelReservation(r.reservationId);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation cancelled.')),
        );
        await _loadReservations();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    }
  }
}

