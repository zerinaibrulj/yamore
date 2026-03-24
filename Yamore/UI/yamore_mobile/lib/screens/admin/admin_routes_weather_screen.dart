import 'package:flutter/material.dart';

import '../../models/city.dart';
import '../../models/reservation.dart';
import '../../models/route.dart';
import '../../models/weather_forecast.dart';
import '../../models/yacht_overview.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class AdminRoutesWeatherScreen extends StatefulWidget {
  final AuthService authService;

  const AdminRoutesWeatherScreen({super.key, required this.authService});

  @override
  State<AdminRoutesWeatherScreen> createState() =>
      _AdminRoutesWeatherScreenState();
}

class _AdminRoutesWeatherScreenState extends State<AdminRoutesWeatherScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  bool _loading = true;
  String? _error;

  List<RouteModel> _routes = [];
  List<CityModel> _cities = [];
  List<YachtOverview> _yachts = [];
  List<Reservation> _reservations = [];
  RouteModel? _selectedRoute;
  List<WeatherForecastModel> _forecasts = [];
  bool _onlyUpcomingConfirmed = true;
  Reservation? _selectedReservationContext;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getRoutes(page: 0, pageSize: 200),
        _api.getCities(),
        _api.getYachtOverviewForAdmin(pageSize: 200),
        _api.getReservations(page: 0, pageSize: 500, status: 'Confirmed'),
      ]);
      final routes = results[0] as List<RouteModel>;
      final cities = results[1] as List<CityModel>;
      final yachts = (results[2] as PagedYachtOverview).resultList;
      final reservations = (results[3] as PagedReservations).resultList;
      final confirmedReservations = reservations
          .where((r) =>
              (r.status ?? '').toLowerCase() == 'confirmed')
          .toList()
        ..sort((a, b) => a.startDate.compareTo(b.startDate));
      final availableRoutes = _onlyUpcomingConfirmed
          ? routes
              .where((route) =>
                  confirmedReservations.any((r) =>
                      r.yachtId == route.yachtId &&
                      !_isReservationPast(r)))
              .toList()
          : routes;
      RouteModel? selected = _selectedRoute;
      if (selected != null &&
          !availableRoutes.any((r) => r.routeId == selected!.routeId)) {
        selected = null;
      }
      if (selected == null && availableRoutes.isNotEmpty) {
        selected = availableRoutes.first;
      }
      List<WeatherForecastModel> forecasts = [];
      if (selected != null) {
        forecasts =
            await _api.getWeatherForecasts(routeId: selected.routeId, pageSize: 50);
      }
      if (!mounted) return;
      setState(() {
        _routes = availableRoutes;
        _cities = cities;
        _yachts = yachts;
        _reservations = confirmedReservations;
        _selectedRoute = selected;
        _selectedReservationContext = _reservationContextsForSelectedRoute
                .contains(_selectedReservationContext)
            ? _selectedReservationContext
            : (_reservationContextsForSelectedRoute.isNotEmpty
                ? _reservationContextsForSelectedRoute.first
                : null);
        _forecasts = forecasts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load data: $e';
        _loading = false;
      });
    }
  }

  CityModel? _cityById(int id) =>
      _cities.firstWhere((c) => c.cityId == id, orElse: () => CityModel.empty());

  List<Reservation> get _reservationContextsForSelectedRoute {
    final route = _selectedRoute;
    if (route == null) return const [];
    return _reservations.where((r) => r.yachtId == route.yachtId).toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  bool _isReservationPast(Reservation r) => r.endDate.isBefore(DateTime.now());

  String _formatDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}h';

  String _formatDateOnly(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year}';

  String _reservationContextLabel(Reservation r) {
    final from = _formatDateOnly(r.startDate);
    final to = _formatDateOnly(r.endDate);
    final past = _isReservationPast(r);
    return past ? '$from  –  $to (passed)' : '$from  –  $to';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
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
              onPressed: _loadAll,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildRoutesCard()),
          const SizedBox(width: 24),
          Expanded(child: _buildWeatherCard()),
        ],
      ),
    );
  }

  Widget _buildRoutesCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Routes',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                FilledButton.icon(
                  onPressed: _openNewRouteDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add route'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Show only routes with upcoming confirmed reservations',
                style: TextStyle(fontSize: 12),
              ),
              value: _onlyUpcomingConfirmed,
              onChanged: (v) {
                setState(() => _onlyUpcomingConfirmed = v);
                _loadAll();
              },
            ),
            const SizedBox(height: 12),
            if (_routes.isEmpty)
              Text(
                _onlyUpcomingConfirmed
                    ? 'No routes currently have upcoming confirmed reservations.'
                    : 'No routes defined yet.',
                style: const TextStyle(fontSize: 13),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _routes.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final r = _routes[index];
                    final startCity = _cityById(r.startCityId);
                    final endCity = _cityById(r.endCityId);
                    final title =
                        '${startCity?.name ?? 'City ${r.startCityId}'} → ${endCity?.name ?? 'City ${r.endCityId}'}';
                    return ListTile(
                      dense: true,
                      title: Text(title),
                      subtitle: r.description != null
                          ? Text(r.description!,
                              maxLines: 1, overflow: TextOverflow.ellipsis)
                          : null,
                      selected: _selectedRoute?.routeId == r.routeId,
                      onTap: () async {
                        final forecasts = await _api.getWeatherForecasts(
                            routeId: r.routeId, pageSize: 50);
                        if (!mounted) return;
                        setState(() {
                          _selectedRoute = r;
                          _forecasts = forecasts;
                        });
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: 'Edit',
                            onPressed: () => _openEditRouteDialog(r),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            tooltip: 'Delete',
                            onPressed: () => _deleteRoute(r),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard() {
    final route = _selectedRoute;
    String title;
    if (route == null) {
      title = 'Weather forecasts';
    } else {
      final startCity = _cityById(route.startCityId);
      final endCity = _cityById(route.endCityId);
      title =
          'Weather – route: ${startCity?.name ?? 'City ${route.startCityId}'} → ${endCity?.name ?? 'City ${route.endCityId}'}';
    }
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                FilledButton.icon(
                  onPressed: route == null
                      ? null
                      : (_selectedReservationContext != null &&
                              _isReservationPast(_selectedReservationContext!))
                          ? null
                          : () => _openNewForecastDialog(route),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add forecast'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (route != null) ...[
              _buildReservationContextCard(),
              const SizedBox(height: 12),
            ],
            if (route == null)
              const Text(
                'Select a route on the left to manage forecasts.',
                style: TextStyle(fontSize: 13),
              )
            else if (_forecasts.isEmpty)
              const Text(
                'No forecasts for this route yet.',
                style: TextStyle(fontSize: 13),
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: _forecasts.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final f = _forecasts[index];
                    final dt = f.forecastDate;
                    final when = dt == null
                        ? 'N/A'
                        : '${dt.day.toString().padLeft(2, '0')}.'
                          '${dt.month.toString().padLeft(2, '0')}.'
                          '${dt.year} ${dt.hour.toString().padLeft(2, '0')}:'
                          '${dt.minute.toString().padLeft(2, '0')}h';
                    return ListTile(
                      dense: true,
                      title: Text(when),
                      subtitle: Text(
                        [
                          if (f.temperature != null)
                            'Temp: ${f.temperature}°C',
                          if (f.windSpeed != null)
                            'Wind: ${f.windSpeed} km/h',
                          if (f.condition != null) f.condition!,
                        ].join(' · '),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () =>
                                _openEditForecastDialog(route, f),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                size: 18, color: Colors.redAccent),
                            onPressed: () => _deleteForecast(f),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationContextCard() {
    final contexts = _reservationContextsForSelectedRoute;
    if (contexts.isEmpty) {
      return const Text(
        'No upcoming confirmed reservations for this yacht. You can still add a forecast manually.',
        style: TextStyle(fontSize: 12),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming confirmed reservations',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<Reservation>(
          value: _selectedReservationContext != null &&
                  contexts.any((r) =>
                      r.reservationId == _selectedReservationContext!.reservationId)
              ? contexts.firstWhere((r) =>
                  r.reservationId == _selectedReservationContext!.reservationId)
              : contexts.first,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            labelText: 'Use reservation date to prefill forecast',
          ),
          items: contexts
              .map(
                (r) => DropdownMenuItem<Reservation>(
                  value: r,
                  enabled: !_isReservationPast(r),
                  child: Text(
                    _reservationContextLabel(r),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _isReservationPast(r)
                          ? Colors.grey.shade500
                          : Colors.black87,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            if (_isReservationPast(v)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Weather forecast can only be added for active/upcoming reservation periods.',
                  ),
                ),
              );
              return;
            }
            setState(() => _selectedReservationContext = v);
          },
        ),
        if (_selectedReservationContext != null &&
            _isReservationPast(_selectedReservationContext!))
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Selected reservation period has passed. Adding forecast is disabled.',
              style: TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ),
      ],
    );
  }

  Future<void> _openNewRouteDialog() async {
    await _openRouteDialog();
  }

  Future<void> _openEditRouteDialog(RouteModel route) async {
    await _openRouteDialog(existing: route);
  }

  Future<void> _openRouteDialog({RouteModel? existing}) async {
    final isEdit = existing != null;
    int? yachtId = existing?.yachtId;
    int? startCityId = existing?.startCityId;
    int? endCityId = existing?.endCityId;
    int? duration = existing?.estimatedDurationHours;
    final descCtrl = TextEditingController(text: existing?.description ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Edit route' : 'New route'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: startCityId,
                decoration: const InputDecoration(
                  labelText: 'Start city',
                  border: OutlineInputBorder(),
                ),
                items: _cities
                    .map((c) => DropdownMenuItem(
                          value: c.cityId,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) => startCityId = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: endCityId,
                decoration: const InputDecoration(
                  labelText: 'End city',
                  border: OutlineInputBorder(),
                ),
                items: _cities
                    .map((c) => DropdownMenuItem(
                          value: c.cityId,
                          child: Text(c.name),
                        ))
                    .toList(),
                onChanged: (v) => endCityId = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: duration,
                decoration: const InputDecoration(
                  labelText: 'Estimated duration (hours)',
                  border: OutlineInputBorder(),
                ),
                items: const [1, 2, 3, 4, 6, 8, 12]
                    .map(
                      (h) => DropdownMenuItem(
                        value: h,
                        child: Text('$h h'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => duration = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: yachtId,
                decoration: const InputDecoration(
                  labelText: 'Yacht',
                  border: OutlineInputBorder(),
                ),
                items: _yachts
                    .map(
                      (y) => DropdownMenuItem(
                        value: y.yachtId,
                        child: Text(
                          y.locationName != null && y.locationName!.isNotEmpty
                              ? '${y.name} (${y.locationName})'
                              : y.name,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => yachtId = v,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (yachtId == null ||
                  startCityId == null ||
                  endCityId == null) {
                return;
              }
              Navigator.of(ctx).pop(true);
            },
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );

    if (confirmed == true &&
        yachtId != null &&
        startCityId != null &&
        endCityId != null) {
      try {
        if (existing == null) {
          await _api.insertRoute(
            yachtId: yachtId!,
            startCityId: startCityId!,
            endCityId: endCityId!,
            estimatedDurationHours: duration,
            description: descCtrl.text.trim().isEmpty
                ? null
                : descCtrl.text.trim(),
          );
        } else {
          await _api.updateRoute(
            routeId: existing.routeId,
            yachtId: yachtId!,
            startCityId: startCityId!,
            endCityId: endCityId!,
            estimatedDurationHours: duration,
            description: descCtrl.text.trim().isEmpty
                ? null
                : descCtrl.text.trim(),
          );
        }
        await _loadAll();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save route: $e')),
        );
      }
    }
    descCtrl.dispose();
  }

  Future<void> _deleteRoute(RouteModel route) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete route'),
        content: const Text(
            'Are you sure you want to delete this route? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteRoute(route.routeId);
        await _loadAll();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete route: $e')),
        );
      }
    }
  }

  Future<void> _openNewForecastDialog(RouteModel route) async {
    await _openForecastDialog(
      route: route,
      prefilledDate: _selectedReservationContext?.startDate,
    );
  }

  Future<void> _openEditForecastDialog(
      RouteModel route, WeatherForecastModel forecast) async {
    await _openForecastDialog(route: route, existing: forecast);
  }

  Future<void> _openForecastDialog({
    required RouteModel route,
    WeatherForecastModel? existing,
    DateTime? prefilledDate,
  }) async {
    final isEdit = existing != null;
    DateTime? date = existing?.forecastDate ?? prefilledDate ?? DateTime.now();
    TimeOfDay time =
        TimeOfDay.fromDateTime(date ?? DateTime.now());
    double? temp = existing?.temperature;
    double? wind = existing?.windSpeed;
    final condCtrl = TextEditingController(text: existing?.condition ?? '');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEdit ? 'Edit forecast' : 'New forecast'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_month, size: 18),
                      label: Text(
                        '${date!.day.toString().padLeft(2, '0')}.'
                        '${date!.month.toString().padLeft(2, '0')}.'
                        '${date!.year}',
                      ),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: ctx,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                          initialDate: date!,
                        );
                        if (picked != null) {
                          date = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                            time.hour,
                            time.minute,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(
                        '${time.hour.toString().padLeft(2, '0')}:'
                        '${time.minute.toString().padLeft(2, '0')}',
                      ),
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: ctx,
                          initialTime: time,
                        );
                        if (picked != null) {
                          time = picked;
                          date = DateTime(
                            date!.year,
                            date!.month,
                            date!.day,
                            time.hour,
                            time.minute,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                value: temp,
                decoration: const InputDecoration(
                  labelText: 'Temperature (°C)',
                  border: OutlineInputBorder(),
                ),
                items: const [-5, 0, 5, 10, 15, 20, 25, 30, 35]
                    .map(
                      (t) => DropdownMenuItem(
                        value: t.toDouble(),
                        child: Text('${t.toString()}°C'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => temp = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<double>(
                value: wind,
                decoration: const InputDecoration(
                  labelText: 'Wind speed (km/h)',
                  border: OutlineInputBorder(),
                ),
                items: const [0, 5, 10, 15, 20, 25, 30, 40, 50]
                    .map(
                      (w) => DropdownMenuItem(
                        value: w.toDouble(),
                        child: Text('${w.toString()} km/h'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => wind = v,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: condCtrl.text.isNotEmpty ? condCtrl.text : null,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  'Sunny',
                  'Partly cloudy',
                  'Cloudy',
                  'Rain',
                  'Storm',
                  'Windy',
                  'Fog'
                ]
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  condCtrl.text = v ?? '';
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );

    if (confirmed == true && date != null) {
      try {
        if (existing == null) {
          await _api.insertWeatherForecast(
            routeId: route.routeId,
            forecastDate: date,
            temperature: temp,
            condition: condCtrl.text.trim().isEmpty
                ? null
                : condCtrl.text.trim(),
            windSpeed: wind,
          );
        } else {
          await _api.updateWeatherForecast(
            forecastId: existing.forecastId,
            routeId: route.routeId,
            forecastDate: date,
            temperature: temp,
            condition: condCtrl.text.trim().isEmpty
                ? null
                : condCtrl.text.trim(),
            windSpeed: wind,
          );
        }
        await _loadAll();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save forecast: $e')),
        );
      }
    }
    condCtrl.dispose();
  }

  Future<void> _deleteForecast(WeatherForecastModel forecast) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete forecast'),
        content: const Text(
            'Are you sure you want to delete this forecast?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteWeatherForecast(forecast.forecastId);
        await _loadAll();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete forecast: $e')),
        );
      }
    }
  }
}

