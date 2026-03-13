import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/yacht_overview.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class MobileBookingReviewScreen extends StatefulWidget {
  final ApiService api;
  final AppUser user;
  final YachtOverview overview;
  final DateTime startDateTime;
  final String durationKey;
  final bool skipperIncluded;
  final String paymentMethod;

  const MobileBookingReviewScreen({
    super.key,
    required this.api,
    required this.user,
    required this.overview,
    required this.startDateTime,
    required this.durationKey,
    required this.skipperIncluded,
    required this.paymentMethod,
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
    final end = _computeEndDate(start, widget.durationKey);
    final durationDays = end.difference(start).inDays.clamp(1, 365);
    final totalPrice = overview.pricePerDay * durationDays;

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
            _buildDetailsRow(start, end, durationDays),
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
      DateTime start, DateTime end, int durationDays) {
    String durationLabel;
    switch (widget.durationKey) {
      case 'half':
        durationLabel = 'Half-day';
        break;
      case 'full':
        durationLabel = 'Full-day';
        break;
      case '2d':
        durationLabel = '2 days';
        break;
      case '3d':
        durationLabel = '3 days';
        break;
      case 'weekend':
        durationLabel = 'Weekend charter';
        break;
      case 'week':
        durationLabel = 'Weekly charter';
        break;
      default:
        durationLabel = '$durationDays days';
    }

    String paymentLabel;
    switch (widget.paymentMethod) {
      case 'card':
        paymentLabel = 'Credit/Debit card';
        break;
      case 'paypal':
        paymentLabel = 'PayPal / Stripe';
        break;
      case 'cash':
        paymentLabel = 'Cash';
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
                const Icon(Icons.person_outline, size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.skipperIncluded ? 'With skipper' : 'Without skipper',
                  style: const TextStyle(fontSize: 13),
                ),
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
          ],
        ),
      ),
    );
  }

  DateTime _computeEndDate(DateTime start, String durationKey) {
    switch (durationKey) {
      case 'half':
        return start.add(const Duration(hours: 4));
      case 'full':
        return start.add(const Duration(days: 1));
      case '2d':
        return start.add(const Duration(days: 2));
      case '3d':
        return start.add(const Duration(days: 3));
      case 'weekend':
        return start.add(const Duration(days: 3));
      case 'week':
        return start.add(const Duration(days: 7));
      default:
        return start.add(const Duration(days: 1));
    }
  }

  Future<void> _confirm(double totalPrice) async {
    setState(() => _saving = true);
    final start = widget.startDateTime;
    final end = _computeEndDate(start, widget.durationKey);
    try {
      await widget.api.createReservation(
        userId: widget.user.userId,
        yachtId: widget.overview.yachtId,
        startDate: start,
        endDate: end,
        totalPrice: totalPrice,
        status: 'Pending',
      );
      if (!mounted) return;
      setState(() => _saving = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Icon(Icons.check_circle,
              size: 48, color: Colors.green),
          content: const Text(
            'Your reservation has been successfully received.\n\nThank you for your trust!',
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
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create reservation: $e')),
      );
    }
  }
}

