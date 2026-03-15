import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/yacht_overview.dart';
import '../../models/route.dart';
import '../../models/weather_forecast.dart';
import '../../models/city.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'mobile_booking_services_screen.dart';

class MobileRouteSelectionScreen extends StatefulWidget {
  final ApiService api;
  final AppUser user;
  final YachtOverview overview;
  final DateTime startDateTime;
  final DateTime endDateTime;

  const MobileRouteSelectionScreen({
    super.key,
    required this.api,
    required this.user,
    required this.overview,
    required this.startDateTime,
    required this.endDateTime,
  });

  @override
  State<MobileRouteSelectionScreen> createState() =>
      _MobileRouteSelectionScreenState();
}

class _MobileRouteSelectionScreenState
    extends State<MobileRouteSelectionScreen> {
  bool _loading = true;
  String? _error;
  List<RouteModel> _routes = [];
  List<CityModel> _cities = [];
  RouteModel? _selectedRoute;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  Future<void> _loadRoutes() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.getRoutesForYacht(widget.overview.yachtId),
        widget.api.getCities(),
      ]);
      final routes = results[0] as List<RouteModel>;
      final cities = results[1] as List<CityModel>;
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _cities = cities;
        if (routes.isNotEmpty) {
          _selectedRoute = routes.first;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load routes: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Choose a route'),
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
                          onPressed: _loadRoutes,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRouteSelector(),
                      const SizedBox(height: 12),
                      if (_selectedRoute != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                            ),
                            onPressed: _showWeather,
                            child: const Text('Weather Along Route'),
                          ),
                        ),
                    ],
                  ),
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
              onPressed: _goNext,
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

  Widget _buildRouteSelector() {
    if (_routes.isEmpty) {
      return const Text(
        'No predefined routes for this yacht. You can continue without selecting a route.',
        style: TextStyle(fontSize: 13),
      );
    }
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose an available route',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RouteModel?>(
              value: _selectedRoute,
              items: [
                const DropdownMenuItem<RouteModel?>(
                  value: null,
                  child: Text('None (no specific route)'),
                ),
                ..._routes.map(
                  (r) => DropdownMenuItem<RouteModel?>(
                    value: r,
                    child: Text(_routeLabel(r)),
                  ),
                ),
              ],
              onChanged: (r) => setState(() => _selectedRoute = r),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _routeLabel(RouteModel r) {
    if (r.description != null && r.description!.trim().isNotEmpty) {
      return r.description!.trim();
    }
    final startCity =
        _cities.firstWhere((c) => c.cityId == r.startCityId, orElse: () => CityModel.empty());
    final endCity =
        _cities.firstWhere((c) => c.cityId == r.endCityId, orElse: () => CityModel.empty());
    if (startCity.cityId != -1 && endCity.cityId != -1) {
      return '${startCity.name} → ${endCity.name}';
    }
    return 'Route #${r.routeId}';
  }

  Future<void> _showWeather() async {
    final route = _selectedRoute;
    if (route == null) return;
    try {
      final forecasts = await widget.api.getWeatherForRoute(route.routeId);
      if (!mounted) return;
      if (forecasts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No weather data for this route.')),
        );
        return;
      }
      final f = forecasts.first;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(_routeLabel(route)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (f.forecastDate != null)
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${f.forecastDate!.day.toString().padLeft(2, '0')}.'
                      '${f.forecastDate!.month.toString().padLeft(2, '0')}.'
                      '${f.forecastDate!.year} '
                      '${f.forecastDate!.hour.toString().padLeft(2, '0')}:'
                      '${f.forecastDate!.minute.toString().padLeft(2, '0')}h',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              if (f.windSpeed != null)
                Row(
                  children: [
                    const Icon(Icons.air, size: 18),
                    const SizedBox(width: 6),
                    Text('Wind: ${f.windSpeed} km/h'),
                  ],
                ),
              if (f.temperature != null)
                Row(
                  children: [
                    const Icon(Icons.thermostat, size: 18),
                    const SizedBox(width: 6),
                    Text('Temperature: ${f.temperature}°C'),
                  ],
                ),
              if (f.condition != null)
                Row(
                  children: [
                    const Icon(Icons.wb_sunny_outlined, size: 18),
                    const SizedBox(width: 6),
                    Text('Condition: ${f.condition}'),
                  ],
                ),
            ],
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

  void _goNext() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileBookingServicesScreen(
          api: widget.api,
          user: widget.user,
          overview: widget.overview,
          startDateTime: widget.startDateTime,
          endDateTime: widget.endDateTime,
        ),
      ),
    );
  }
}
