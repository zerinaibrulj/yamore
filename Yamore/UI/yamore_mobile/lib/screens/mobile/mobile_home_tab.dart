import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/yacht_overview.dart';

class MobileHomeTab extends StatefulWidget {
  final AuthService authService;
  final AppUser user;

  const MobileHomeTab({super.key, required this.authService, required this.user});

  @override
  State<MobileHomeTab> createState() => _MobileHomeTabState();
}

class _MobileHomeTabState extends State<MobileHomeTab> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  List<YachtOverview> _yachts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadYachts();
  }

  Future<void> _loadYachts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getYachtOverviewForAdmin(pageSize: 20);
      if (mounted) {
        setState(() {
          _yachts = result.resultList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load yachts: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadYachts,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primaryBlue.withOpacity(0.08),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${widget.user.firstName}!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1a237e),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Discover yachts for your next adventure',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: const [
                  Icon(Icons.directions_boat, size: 20, color: Color(0xFF1a237e)),
                  SizedBox(width: 8),
                  Text(
                    'Available Yachts',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    FilledButton(onPressed: _loadYachts, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_yachts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No yachts available at the moment.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final yacht = _yachts[index];
                    return _YachtCard(yacht: yacht, api: _api);
                  },
                  childCount: _yachts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _YachtCard extends StatelessWidget {
  final YachtOverview yacht;
  final ApiService api;

  const _YachtCard({required this.yacht, required this.api});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (yacht.thumbnailImageId != null)
            Image.network(
              api.yachtImageUrl(yacht.thumbnailImageId!),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              headers: api.authHeaders,
              errorBuilder: (_, __, ___) => _placeholderImage(),
            )
          else
            _placeholderImage(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  yacht.name,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                if (yacht.locationName != null)
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        yacht.locationName!,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chip(Icons.people_outline, '${yacht.capacity} guests'),
                    const SizedBox(width: 8),
                    if (yacht.yearBuilt != null)
                      _chip(Icons.calendar_today_outlined, '${yacht.yearBuilt}'),
                    const Spacer(),
                    Text(
                      '€${yacht.pricePerDay.toStringAsFixed(0)}/day',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1a237e),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  static Widget _placeholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sailing, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text('No image', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }
}
