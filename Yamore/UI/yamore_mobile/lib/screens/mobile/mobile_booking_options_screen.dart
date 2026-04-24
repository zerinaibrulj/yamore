import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../models/yacht_overview.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'mobile_route_selection_screen.dart';

class MobileBookingOptionsScreen extends StatefulWidget {
  final ApiService api;
  final AppUser user;
  final YachtOverview overview;
  final AuthService authService;
  final DateTime startDateTime;

  const MobileBookingOptionsScreen({
    super.key,
    required this.api,
    required this.user,
    required this.overview,
    required this.authService,
    required this.startDateTime,
  });

  @override
  State<MobileBookingOptionsScreen> createState() =>
      _MobileBookingOptionsScreenState();
}

class _MobileBookingOptionsScreenState
    extends State<MobileBookingOptionsScreen> {
  bool? _skipperYes; // true = yes, false = no
  String? _durationKey;

  final Map<String, String> _durationLabels = const {
    'half': 'Half-day',
    'full': 'Full-day',
    '2d': '2 days',
    '3d': '3 days',
    'weekend': 'Weekend charter',
    'week': 'Weekly charter',
  };

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
        title: const Text('Trip options'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkipperCard(),
            const SizedBox(height: 16),
            _buildDurationCard(),
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
              onPressed:
                  _durationKey == null ? null : _goNext,
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

  Widget _buildSkipperCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Do you want a skipper for your trip?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Yes'),
                    selected: _skipperYes == true,
                    onSelected: (_) => setState(() => _skipperYes = true),
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: _skipperYes == true
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('No'),
                    selected: _skipperYes == false,
                    onSelected: (_) => setState(() => _skipperYes = false),
                    selectedColor: AppTheme.primaryBlue,
                    labelStyle: TextStyle(
                      color: _skipperYes == false
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Select "Yes" if you prefer a professional captain. '
              'Select "No" if you will operate the yacht yourself (with a valid license).',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select rental duration',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ..._durationLabels.entries.map(
              (e) => RadioListTile<String>(
                value: e.key,
                groupValue: _durationKey,
                title: Text(e.value),
                dense: true,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _durationKey = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goNext() {
    if (_durationKey == null) return;
    final endDateTime = _calculateEndDateTime(widget.startDateTime, _durationKey!);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileRouteSelectionScreen(
          api: widget.api,
          user: widget.user,
          overview: widget.overview,
          authService: widget.authService,
          startDateTime: widget.startDateTime,
          endDateTime: endDateTime,
        ),
      ),
    );
  }

  DateTime _calculateEndDateTime(DateTime start, String durationKey) {
    return switch (durationKey) {
      'half' => start.add(const Duration(hours: 12)),
      'full' => start.add(const Duration(days: 1)),
      '2d' => start.add(const Duration(days: 2)),
      '3d' => start.add(const Duration(days: 3)),
      'weekend' => start.add(const Duration(days: 2)),
      'week' => start.add(const Duration(days: 7)),
      _ => start.add(const Duration(days: 1)),
    };
  }
}

