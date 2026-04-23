import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

import '../../models/user.dart';
import '../../models/yacht_overview.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../models/service_model.dart';
import '../../theme/app_theme.dart';
import 'mobile_shell.dart';

String _formatCharterPeriod(DateTime start, DateTime end) {
  const months = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  String line(DateTime d) => '${d.day} ${months[d.month - 1]} ${d.year}';
  return '${line(start)} - ${line(end)}';
}

class MobileBookingReviewScreen extends StatefulWidget {
  final ApiService api;
  final AppUser user;
  final YachtOverview overview;
  final AuthService authService;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final String paymentMethod;
  final List<ServiceModel> selectedServices;
  final String selectedRouteLabel;

  const MobileBookingReviewScreen({
    super.key,
    required this.api,
    required this.user,
    required this.overview,
    required this.authService,
    required this.startDateTime,
    required this.endDateTime,
    required this.paymentMethod,
    this.selectedServices = const [],
    required this.selectedRouteLabel,
  });

  @override
  State<MobileBookingReviewScreen> createState() =>
      _MobileBookingReviewScreenState();
}

class _MobileBookingReviewScreenState extends State<MobileBookingReviewScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    final user = widget.user;
    final start = widget.startDateTime;
    final end = widget.endDateTime;
    final durationDays = end.difference(start).inDays.clamp(1, 365);
    double servicesTotal = 0;
    for (final s in widget.selectedServices) {
      if (s.price != null && s.price! > 0) servicesTotal += s.price!;
    }
    final totalPrice = overview.pricePerDay * durationDays + servicesTotal;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Reservation review'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: overview.thumbnailImageId != null
                  ? Image.network(
                      widget.api.yachtImageUrl(overview.thumbnailImageId!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      headers: widget.api.authHeaders,
                    )
                  : Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: Icon(Icons.sailing,
                          size: 56, color: Colors.grey.shade400),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              overview.name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            _buildContactCard(user),
            const SizedBox(height: 12),
            _buildDetailsRow(start, end, durationDays, totalPrice),
            if (widget.selectedServices.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSelectedServicesCard(),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.center,
              child: Text(
                'Please review all details before confirming your reservation.',
                style:
                    TextStyle(fontSize: 13, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
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
              onPressed: _saving ? null : () => _confirm(totalPrice),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'CONFIRM',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedServicesCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selected services',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ...widget.selectedServices.map((s) {
              final icon = _serviceIcon(s.name);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: AppTheme.primaryBlue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          if (s.description != null && s.description!.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                s.description!.trim(),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (s.price != null && s.price! > 0)
                      Text('€${s.price!.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _serviceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('drink') || n.contains('welcome'))
      return Icons.local_bar;
    if (n.contains('food') || n.contains('meal'))
      return Icons.restaurant;
    if (n.contains('music'))
      return Icons.music_note;
    if (n.contains('pet'))
      return Icons.pets;
    if (n.contains('safety') || n.contains('life jacket'))
      return Icons.health_and_safety;
    return Icons.check_circle_outline;
  }

  Widget _buildContactCard(AppUser user) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('Full name: ${user.displayName}',
                style: const TextStyle(fontSize: 13)),
            if (user.email != null)
              Text('Email: ${user.email}',
                  style: const TextStyle(fontSize: 13)),
            if (user.phone != null)
              Text('Phone: ${user.phone}',
                  style: const TextStyle(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsRow(
      DateTime start, DateTime end, int durationDays, double totalPrice) {
    final durationLabel = '$durationDays day${durationDays == 1 ? '' : 's'}';
    String paymentLabel;
    switch (widget.paymentMethod) {
      case 'card':
        paymentLabel = 'Credit/Debit card (Stripe)';
        break;
      case 'cash':
        paymentLabel = 'Pay on arrival';
        break;
      default:
        paymentLabel = widget.paymentMethod;
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
              'Trip details',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${start.day.toString().padLeft(2, '0')}.'
                  '${start.month.toString().padLeft(2, '0')}.'
                  '${start.year}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${start.hour.toString().padLeft(2, '0')}:'
                  '${start.minute.toString().padLeft(2, '0')}h',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18),
                const SizedBox(width: 6),
                Text(durationLabel,
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.payment, size: 18),
                const SizedBox(width: 6),
                Text(paymentLabel,
                    style: const TextStyle(fontSize: 13)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.route_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.selectedRouteLabel,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const Spacer(),
                Text('€${totalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirm(double totalPrice) async {
    setState(() => _saving = true);
    final start = widget.startDateTime;
    final end = widget.endDateTime;
    try {
      final isCard = widget.paymentMethod == 'card';
      String offlineMethod = 'Cash';
      if (isCard) {
        // No reservation in DB until Stripe reports success. Server recalculates the total to match the PaymentIntent.
        final intentResult = await widget.api.prepareCardBooking(
          userId: widget.user.userId,
          yachtId: widget.overview.yachtId,
          startDate: start,
          endDate: end,
          serviceIds: widget.selectedServices.map((s) => s.serviceId).toList(),
        );
        final clientSecret = intentResult.clientSecret;
        final paymentIntentId = intentResult.paymentIntentId;
        if (clientSecret == null || clientSecret.isEmpty) {
          if (!mounted) return;
          setState(() => _saving = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Card payment is not available. Check Stripe settings or choose Pay on arrival.',
              ),
            ),
          );
          return;
        }
        final publishableKey = await widget.api.getStripePublishableKey();
        if (publishableKey.isEmpty) {
          if (!mounted) return;
          setState(() => _saving = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment configuration missing. Please try Pay on arrival.')),
          );
          return;
        }
        Stripe.publishableKey = publishableKey;
        try {
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              paymentIntentClientSecret: clientSecret,
              merchantDisplayName: 'Yamore',
            ),
          );
          await Stripe.instance.presentPaymentSheet();
        } on StripeException catch (e) {
          if (!mounted) return;
          setState(() => _saving = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment cancelled or failed: ${e.error?.localizedMessage ?? e.toString()}')),
          );
          return;
        } catch (e) {
          if (!mounted) return;
          setState(() => _saving = false);
          if (!mounted) return;
          final msg = e.toString();
          if (msg.contains('MissingPluginException') || msg.contains('flutter.stripe')) {
            await showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                icon: Icon(Icons.credit_card_off, size: 40, color: Colors.orange.shade700),
                title: const Text('Card payment not available'),
                content: const Text(
                  'Payment by card is not possible on this device. Please choose "Pay on arrival" (cash) instead.',
                  textAlign: TextAlign.center,
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            if (!mounted) return;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment failed: $e')),
            );
          }
          return;
        }
        await widget.api.confirmPayment(
          paymentIntentId: paymentIntentId,
        );
      } else {
        final reservation = await widget.api.createReservation(
          userId: widget.user.userId,
          yachtId: widget.overview.yachtId,
          startDate: start,
          endDate: end,
          totalPrice: totalPrice,
          status: 'Pending',
        );
        for (final s in widget.selectedServices) {
          await widget.api.addServiceToReservation(
            reservationId: reservation.reservationId,
            serviceId: s.serviceId,
          );
        }
        offlineMethod = 'Cash';
        await widget.api.confirmPayment(
          reservationId: reservation.reservationId,
          paymentMethod: offlineMethod,
        );
      }

      if (!mounted) return;
      setState(() => _saving = false);
      final yachtName = widget.overview.name;
      final periodLabel = _formatCharterPeriod(start, end);
      final successBody = isCard
          ? 'Your payment was successful and your reservation is now confirmed.\n\n'
              'Yacht: $yachtName\n'
              'Charter period: $periodLabel\n\n'
              'A confirmation email will be sent to you shortly. Thank you for choosing Yamore.'
          : 'Your booking request has been received.\n\n'
              'Yacht: $yachtName\n'
              'Charter period: $periodLabel\n\n'
              '${offlineMethod == 'Cash' ? 'Payment is due on arrival (cash or bank transfer, as agreed with the operator).' : 'Payment will be arranged separately.'}\n\n'
              'We will contact you if we need any further information. Thank you for choosing Yamore.';
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Icon(Icons.check_circle, size: 48, color: Colors.green),
          content: Text(
            successBody,
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      // Always return to the Home tab after a successful reservation.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => MobileShell(
            user: widget.user,
            authService: widget.authService,
          ),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final bodyLower = e.displayMessage.toLowerCase();
      final msg = bodyLower.contains('already reserved') || bodyLower.contains('selected dates')
          ? 'This yacht is already reserved for the selected dates. Please choose different dates or times.'
          : (e.displayMessage.isNotEmpty ? e.displayMessage : 'Request failed.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 5)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }
}

