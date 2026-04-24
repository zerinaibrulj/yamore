import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/yacht_overview.dart';
import '../../models/service_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/yamore_service_icon.dart';
import 'mobile_booking_payment_screen.dart';

class MobileBookingServicesScreen extends StatefulWidget {
  final ApiService api;
  final AppUser user;
  final YachtOverview overview;
  final AuthService authService;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String selectedRouteLabel;

  const MobileBookingServicesScreen({
    super.key,
    required this.api,
    required this.user,
    required this.overview,
    required this.authService,
    required this.startDateTime,
    required this.endDateTime,
    required this.selectedRouteLabel,
  });

  @override
  State<MobileBookingServicesScreen> createState() =>
      _MobileBookingServicesScreenState();
}

class _MobileBookingServicesScreenState
    extends State<MobileBookingServicesScreen> {
  bool _loading = true;
  String? _error;
  List<ServiceModel> _services = [];
  final Set<int> _selectedServiceIds = {};

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ids = await widget.api.getYachtServiceIds(widget.overview.yachtId);
      if (ids.isEmpty) {
        if (!mounted) return;
        setState(() {
          _services = [];
          _loading = false;
        });
        return;
      }
      final result = await widget.api.getServices(pageSize: 200);
      final all = result.resultList;
      final list = all.where((s) => ids.contains(s.serviceId)).toList();
      if (!mounted) return;
      setState(() {
        _services = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load services: $e';
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
        title: const Text('Services offered'),
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
                          onPressed: _loadServices,
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
                      Text(
                        '${widget.overview.name} offers the following services:',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_services.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No special services are listed for this yacht. You can continue to the next step.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _services.length,
                            itemBuilder: (context, index) {
                              final s = _services[index];
                              final selected = _selectedServiceIds.contains(s.serviceId);
                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: CheckboxListTile(
                                  value: selected,
                                  onChanged: (v) {
                                    setState(() {
                                      if (v == true) {
                                        _selectedServiceIds.add(s.serviceId);
                                      } else {
                                        _selectedServiceIds.remove(s.serviceId);
                                      }
                                    });
                                  },
                                  secondary: CircleAvatar(
                                    backgroundColor: AppTheme.primaryBlue.withOpacity(0.15),
                                    child: Icon(
                                      yamoreServiceIcon(s),
                                      color: AppTheme.primaryBlue,
                                      size: 22,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          s.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      if (s.price != null && s.price! > 0)
                                        Text(
                                          '€${s.price!.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: (s.description != null &&
                                          s.description!.trim().isNotEmpty)
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            s.description!.trim(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              );
                            },
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

  void _goNext() {
    final selectedServices = _services
        .where((s) => _selectedServiceIds.contains(s.serviceId))
        .toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileBookingPaymentScreen(
          api: widget.api,
          user: widget.user,
          overview: widget.overview,
          authService: widget.authService,
          startDateTime: widget.startDateTime,
          endDateTime: widget.endDateTime,
          selectedServices: selectedServices,
          selectedRouteLabel: widget.selectedRouteLabel,
        ),
      ),
    );
  }
}
