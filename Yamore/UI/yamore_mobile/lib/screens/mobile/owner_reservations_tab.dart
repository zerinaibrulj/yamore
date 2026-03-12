import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/reservation.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class OwnerReservationsTab extends StatefulWidget {
  final AuthService authService;
  final AppUser user;

  const OwnerReservationsTab({super.key, required this.authService, required this.user});

  @override
  State<OwnerReservationsTab> createState() => _OwnerReservationsTabState();
}

class _OwnerReservationsTabState extends State<OwnerReservationsTab> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  List<Reservation> _reservations = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'All';

  static const _statuses = ['All', 'Pending', 'Confirmed', 'Cancelled'];

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
        pageSize: 50,
        status: _filterStatus == 'All' ? null : _filterStatus,
      );
      if (mounted) {
        setState(() {
          _reservations = result.resultList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reservations: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _cancelReservation(Reservation r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Reservation'),
        content: Text('Cancel reservation #${r.reservationId}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Cancel It'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.cancelReservation(r.reservationId);
        await _loadReservations();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_bottom;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadReservations,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Icon(Icons.calendar_month, color: AppTheme.primaryBlue, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Reservations',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _statuses.map((s) {
                final selected = s == _filterStatus;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(s),
                    selected: selected,
                    onSelected: (_) {
                      setState(() => _filterStatus = s);
                      _loadReservations();
                    },
                    selectedColor: AppTheme.primaryBlue.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: selected ? AppTheme.primaryBlue : Colors.grey.shade700,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadReservations, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_reservations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No reservations found.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      itemCount: _reservations.length,
      itemBuilder: (context, index) {
        final r = _reservations[index];
        final color = _statusColor(r.status);
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1.5,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_statusIcon(r.status), color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      r.status ?? 'Unknown',
                      style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const Spacer(),
                    Text(
                      '#${r.reservationId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const Divider(height: 18),
                _infoRow(Icons.directions_boat_outlined, 'Yacht ID', r.yachtId.toString()),
                _infoRow(Icons.person_outline, 'Guest ID', r.userId.toString()),
                _infoRow(Icons.date_range, 'Period', '${_fmtDate(r.startDate)} – ${_fmtDate(r.endDate)}'),
                _infoRow(Icons.timelapse, 'Duration', '${r.durationDays} day${r.durationDays == 1 ? '' : 's'}'),
                if (r.totalPrice != null)
                  _infoRow(Icons.euro, 'Total', '€${r.totalPrice!.toStringAsFixed(2)}'),
                if (r.status?.toLowerCase() != 'cancelled') ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _cancelReservation(r),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Cancel'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
