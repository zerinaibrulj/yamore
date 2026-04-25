import 'package:flutter/material.dart';

import '../../utils/payment_platform.dart';
import '../../models/user.dart';
import '../../models/yacht_overview.dart';
import '../../models/service_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'mobile_booking_review_screen.dart';

class MobileBookingPaymentScreen extends StatefulWidget {
  final ApiService api;
  final AppUser user;
  final YachtOverview overview;
  final AuthService authService;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final List<ServiceModel> selectedServices;
  final String selectedRouteLabel;

  const MobileBookingPaymentScreen({
    super.key,
    required this.api,
    required this.user,
    required this.overview,
    required this.authService,
    required this.startDateTime,
    required this.endDateTime,
    this.selectedServices = const [],
    required this.selectedRouteLabel,
  });

  @override
  State<MobileBookingPaymentScreen> createState() =>
      _MobileBookingPaymentScreenState();
}

class _MobileBookingPaymentScreenState
    extends State<MobileBookingPaymentScreen> {
  String _paymentMethod = 'card';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (!isStripeCardPaymentAvailable) {
      _paymentMethod = 'cash';
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
        title: const Text('Payment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildPaymentCard(),
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
              onPressed: _saving ? null : _goNext,
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

  Widget _buildSummaryCard() {
    final start = widget.startDateTime;
    final end = widget.endDateTime;
    final duration = end.difference(start).inDays.clamp(1, 365);
    final basePrice = widget.overview.pricePerDay * duration;
    double servicesTotal = 0;
    for (final s in widget.selectedServices) {
      if (s.price != null && s.price! > 0) servicesTotal += s.price!;
    }
    final totalPrice = basePrice + servicesTotal;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Booking summary',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '${start.day}.${start.month}.${start.year} '
              '– ${end.day}.${end.month}.${end.year}',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Duration: $duration day${duration == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 13),
            ),
            if (widget.selectedServices.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 4),
              ...widget.selectedServices.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text('• ${s.name}', style: const TextStyle(fontSize: 13)),
                        const Spacer(),
                        if (s.price != null && s.price! > 0)
                          Text(
                            '€${s.price!.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 13),
                          ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            if (widget.selectedServices.isNotEmpty && servicesTotal > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Text('Base (yacht)', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    Text('€${basePrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            Row(
              children: [
                const Text(
                  'Total price',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '€${totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isStripeCardPaymentAvailable) ...[
              Semantics(
                liveRegion: true,
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.amber.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 22, color: Colors.amber.shade900),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Stripe payment is not available on desktop. Please choose Pay on arrival (Cash) to complete your booking, or use the Yamore app on an iOS or Android phone to pay by card.',
                            style: TextStyle(fontSize: 13, height: 1.35),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const Text(
              'Please select your preferred payment method',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            if (isStripeCardPaymentAvailable)
              Text(
                'Card payments are secure and powered by Stripe.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              )
            else
              Text(
                'On this device, card checkout is not offered — please select Pay on arrival below.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
              ),
            const SizedBox(height: 12),
            RadioListTile<String>(
              value: 'card',
              groupValue: _paymentMethod,
              dense: true,
              title: const Row(
                children: [
                  Icon(Icons.credit_card, size: 20),
                  SizedBox(width: 8),
                  Text('Credit/Debit card (Stripe)'),
                ],
              ),
              subtitle: Text(
                isStripeCardPaymentAvailable
                    ? 'Pay now – secure online payment'
                    : 'Only in the iOS or Android app',
                style: const TextStyle(fontSize: 12),
              ),
              onChanged: isStripeCardPaymentAvailable
                  ? (v) => setState(() => _paymentMethod = v!)
                  : null,
            ),
            RadioListTile<String>(
              value: 'cash',
              groupValue: _paymentMethod,
              dense: true,
              title: const Row(
                children: [
                  Icon(Icons.payments_outlined, size: 20),
                  SizedBox(width: 8),
                  Text('Pay on arrival'),
                ],
              ),
              subtitle: const Text('Cash or bank transfer – pay when you board', style: TextStyle(fontSize: 12)),
              onChanged: (v) => setState(() => _paymentMethod = v!),
            ),
          ],
        ),
      ),
    );
  }

  void _goNext() {
    if (_saving) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileBookingReviewScreen(
          api: widget.api,
          user: widget.user,
          overview: widget.overview,
          authService: widget.authService,
          startDateTime: widget.startDateTime,
          endDateTime: widget.endDateTime,
          paymentMethod: _paymentMethod,
          selectedServices: widget.selectedServices,
          selectedRouteLabel: widget.selectedRouteLabel,
        ),
      ),
    );
  }
}

