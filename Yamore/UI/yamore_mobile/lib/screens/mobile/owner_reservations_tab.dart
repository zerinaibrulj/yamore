import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/operation_success_dialog.dart';
import '../../models/reservation.dart';
import '../../models/user.dart';
import '../../models/yacht_detail.dart';
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
  List<Reservation> _allReservations = [];
  bool _loading = true;
  String? _error;
  String _filterStatus = 'All';

  static const int _pageSize = 10;
  int _page = 0;

  final ScrollController _listScrollController = ScrollController();

  final Map<int, YachtDetail> _yachtCache = {};
  final Map<int, AppUser> _guestCache = {};

  static const _statuses = ['All', 'Pending', 'Confirmed', 'Cancelled'];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  void _scrollReservationsListToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_listScrollController.hasClients) return;
      _listScrollController.jumpTo(0);
    });
  }

  Future<void> _applyStatusFilter() async {
    final list = _filterStatus == 'All'
        ? _allReservations
        : _allReservations
            .where((r) =>
                (r.status ?? '').toLowerCase() == _filterStatus.toLowerCase())
            .toList();

    final yachtIds = list.map((r) => r.yachtId).toSet();
    final userIds = list.map((r) => r.userId).toSet();

    await Future.wait([
      ...yachtIds
          .where((id) => !_yachtCache.containsKey(id))
          .map((id) async {
        try {
          final d = await _api.getYachtById(id);
          _yachtCache[id] = d;
        } catch (e) {
          debugPrint('Failed to preload yacht $id: $e');
        }
      }),
      ...userIds
          .where((id) => !_guestCache.containsKey(id))
          .map((id) async {
        try {
          final u = await _api.getUserById(id);
          _guestCache[id] = u;
        } catch (e) {
          debugPrint('Failed to preload guest $id: $e');
        }
      }),
    ]);

    if (!mounted) return;
    setState(() {
      _reservations = list;
      _page = 0;
      _loading = false;
    });
  }

  Future<void> _loadReservations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final myYachtsPaged = await _api.getMyYachts(page: 0, pageSize: 200);
      final myYachtIds = myYachtsPaged.resultList.map((y) => y.yachtId).toSet();

      if (myYachtIds.isEmpty) {
        if (!mounted) return;
        setState(() {
          _allReservations = [];
          _reservations = [];
          _page = 0;
          _loading = false;
        });
        return;
      }

      final ownerReservations = <Reservation>[];
      const batchSize = 200;
      var page = 0;
      while (true) {
        final result = await _api.getReservations(page: page, pageSize: batchSize);
        final batch = result.resultList
            .where((r) => myYachtIds.contains(r.yachtId))
            .toList();
        ownerReservations.addAll(batch);

        if (result.resultList.isEmpty) break;
        if (result.count != null && (page + 1) * batchSize >= result.count!) break;
        page++;
      }

      if (!mounted) return;
      setState(() {
        _allReservations = ownerReservations;
        _reservations = [];
        _loading = true;
        _page = 0;
      });

      await _applyStatusFilter();
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
        content: const Text('Are you sure you want to cancel this reservation?'),
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
        final cancelResult = await _api.cancelReservation(r.reservationId);
        await _loadReservations();
        if (mounted) {
          await showOperationSuccessDialog(
            context,
            title: 'Reservation cancelled',
            message: cancelResult.hadCardPayment
                ? 'The reservation is cancelled. A card payment was on file—ask the guest to contact support for refund questions if needed.'
                : 'The reservation has been cancelled successfully.',
          );
          _scrollReservationsListToTop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmReservation(Reservation r) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Reservation'),
        content: const Text('Are you sure you want to confirm this reservation?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.confirmReservation(r.reservationId);
        await _loadReservations();
        if (mounted) {
          await showOperationSuccessDialog(
            context,
            title: 'Reservation confirmed',
            message: 'The reservation has been confirmed successfully.',
          );
          _scrollReservationsListToTop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to confirm: $e')),
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

  int _countStatus(String status) {
    return _allReservations
        .where((r) => (r.status ?? '').toLowerCase() == status.toLowerCase())
        .length;
  }

  Widget _buildSummaryCards() {
    Widget statCard({
      required String label,
      required int value,
      required Color color,
      required IconData icon,
    }) {
      return Container(
        constraints: const BoxConstraints(minWidth: 145),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$label: $value',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        runSpacing: 8,
        children: [
          statCard(
            label: 'Total',
            value: _allReservations.length,
            color: AppTheme.primaryBlue,
            icon: Icons.receipt_long,
          ),
          statCard(
            label: 'Pending',
            value: _countStatus('pending'),
            color: Colors.orange.shade700,
            icon: Icons.hourglass_bottom,
          ),
          statCard(
            label: 'Confirmed',
            value: _countStatus('confirmed'),
            color: Colors.green.shade700,
            icon: Icons.check_circle,
          ),
          statCard(
            label: 'Cancelled',
            value: _countStatus('cancelled'),
            color: Colors.red.shade700,
            icon: Icons.cancel,
          ),
        ],
      ),
    );
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
                    onSelected: (_) async {
                      if (_loading) return;
                      setState(() {
                        _filterStatus = s;
                        _loading = true;
                        _error = null;
                      });
                      await _applyStatusFilter();
                      if (mounted) _scrollReservationsListToTop();
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
          if (!_loading && _error == null) _buildSummaryCards(),
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

    final total = _reservations.length;
    final totalPages = (total / _pageSize).ceil();
    final maxPage = totalPages > 0 ? totalPages - 1 : 0;
    final effectivePage = _page.clamp(0, maxPage);
    if (effectivePage != _page) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _page = effectivePage);
      });
    }
    final start = effectivePage * _pageSize;
    final end = (start + _pageSize).clamp(0, total);
    final pageItems = _reservations.sublist(start, end);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _listScrollController,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            itemCount: pageItems.length,
            itemBuilder: (context, index) {
              final r = pageItems[index];
        final yacht = _yachtCache[r.yachtId];
        final guest = _guestCache[r.userId];
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
                  ],
                ),
                const Divider(height: 18),
                _infoRow(
                  Icons.directions_boat_outlined,
                  'Yacht',
                  yacht?.name ?? 'Unknown yacht',
                ),
                _infoRow(
                  Icons.person_outline,
                  'Guest',
                  guest?.displayName ?? 'Guest user',
                ),
                _infoRow(Icons.date_range, 'Period', '${_fmtDate(r.startDate)} – ${_fmtDate(r.endDate)}'),
                _infoRow(Icons.timelapse, 'Duration', '${r.durationDays} day${r.durationDays == 1 ? '' : 's'}'),
                if (r.totalPrice != null)
                  _infoRow(Icons.euro, 'Total', '€${r.totalPrice!.toStringAsFixed(2)}'),
                if (r.status?.toLowerCase() != 'cancelled') ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if ((r.status ?? '').toLowerCase() == 'pending')
                        TextButton.icon(
                          onPressed: () => _confirmReservation(r),
                          icon: const Icon(Icons.check_circle_outline, size: 18),
                          label: const Text('Confirm'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green.shade700,
                          ),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () => _cancelReservation(r),
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
            },
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: effectivePage > 0
                          ? () {
                              setState(() => _page = effectivePage - 1);
                              _scrollReservationsListToTop();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_left, size: 16),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: EdgeInsets.zero,
                      tooltip: 'Previous page',
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Page ${effectivePage + 1} of $totalPages',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                    IconButton(
                      onPressed: effectivePage < totalPages - 1
                          ? () {
                              setState(() => _page = effectivePage + 1);
                              _scrollReservationsListToTop();
                            }
                          : null,
                      icon: const Icon(Icons.chevron_right, size: 16),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: EdgeInsets.zero,
                      tooltip: 'Next page',
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
