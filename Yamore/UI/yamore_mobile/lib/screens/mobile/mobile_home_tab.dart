import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/favorites_service.dart';
import '../../models/yacht_overview.dart';
import '../../models/city.dart';
import '../../models/yacht_category.dart';
import '../../widgets/custom_date_range_picker_dialog.dart';
import 'mobile_yacht_detail_screen.dart';

class MobileHomeTab extends StatefulWidget {
  final AuthService authService;
  final AppUser user;
  final bool showOnlyFavorites;

  const MobileHomeTab({
    super.key,
    required this.authService,
    required this.user,
    this.showOnlyFavorites = false,
  });

  @override
  State<MobileHomeTab> createState() => _MobileHomeTabState();
}

class _MobileHomeTabState extends State<MobileHomeTab> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  List<YachtOverview> _allYachts = [];
  List<YachtOverview> _filteredYachts = [];
  List<YachtOverview> _recommended = [];
  List<CityModel> _cities = [];
  List<YachtCategoryModel> _categories = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _destinationCtrl = TextEditingController();
  final TextEditingController _searchNameCtrl = TextEditingController();
  DateTimeRange? _dateRange;
  int _guests = 2;
  int? _selectedCityId;
  Set<int> _favoriteIds = {};
  String _selectedType = 'All'; // All, Sailing, Motor, Catamaran
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void didUpdateWidget(covariant MobileHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showOnlyFavorites != widget.showOnlyFavorites) {
      // Re-apply filters when switching between Home and Favorites tabs.
      _applyFilters();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getYachtOverviewForAdmin(pageSize: 50),
        _api.getCities(),
        _api.getYachtCategories(),
        FavoritesService.loadFavorites(widget.user.userId),
      ]);
      final overview = results[0] as PagedYachtOverview;
      final cities = results[1] as List<CityModel>;
      final cats = results[2] as List<YachtCategoryModel>;
      final favs = results[3] as Set<int>;
      if (mounted) {
        setState(() {
          _allYachts = overview.resultList;
          _cities = cities;
          _categories = cats;
          _favoriteIds = favs;
          _buildRecommended();
          _applyFilters();
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
      onRefresh: _loadInitial,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          if (!widget.showOnlyFavorites && _recommended.isNotEmpty)
            SliverToBoxAdapter(child: _buildRecommendedStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildListHeader()),
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
                    FilledButton(onPressed: _loadInitial, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          else if (_filteredYachts.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No yachts available at the moment.')),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final yacht = _filteredYachts[index];
                    final isFav = _favoriteIds.contains(yacht.yachtId);
                    return _YachtCard(
                      yacht: yacht,
                      api: _api,
                      isFavorite: isFav,
                      onToggleFavorite: () =>
                          _toggleFavorite(yacht.yachtId, !isFav),
                      onTap: () => _openYachtDetails(yacht),
                    );
                  },
                  childCount: _filteredYachts.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── UI building blocks ──

extension on _MobileHomeTabState {
  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF102a6b), Color(0xFF1a237e)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Book your next boating trip',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Find the perfect yacht in a few taps.',
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
          ),
          const SizedBox(height: 18),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _destinationCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Destination',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickDates,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Dates',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _dateRange == null
                            ? 'Flexible'
                            : '${_dateRange!.start.day}.${_dateRange!.start.month}.${_dateRange!.start.year} – '
                              '${_dateRange!.end.day}.${_dateRange!.end.month}.${_dateRange!.end.year}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _pickGuests,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Guests',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.people_outline),
                      ),
                      child: Text('$_guests adult${_guests > 1 ? 's' : ''}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _applyFilters,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Search'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended for you',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommended.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final y = _recommended[index];
                return SizedBox(
                  width: 220,
                  child: _YachtCard(
                    yacht: y,
                    api: _api,
                    isFavorite: false,
                    onToggleFavorite: () {},
                    showFavoriteIcon: false,
                    onTap: () => _openYachtDetails(y),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.directions_boat, size: 20, color: Color(0xFF1a237e)),
              SizedBox(width: 8),
              Text(
                'Available Yachts',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _filterChip(icon: Icons.tune, label: 'Filter', onTap: _openFilterSheet),
              const SizedBox(width: 8),
              _filterChip(
                icon: Icons.swap_vert,
                label: _sortAscending ? 'Price ↑' : 'Price ↓',
                onTap: () {
                  setState(() => _sortAscending = !_sortAscending);
                  _applyFilters();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _searchNameCtrl,
            decoration: const InputDecoration(
              hintText: 'Search yacht name',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _applyFilters(),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  void _buildRecommended() {
    // For now just take the top 3 by price as \"featured\".
    final sorted = [..._allYachts]..sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
    _recommended = sorted.take(3).toList();
  }

  void _applyFilters() {
    var list = [..._allYachts];
    final dest = _destinationCtrl.text.trim().toLowerCase();
    final name = _searchNameCtrl.text.trim().toLowerCase();

    if (dest.isNotEmpty) {
      list = list
          .where((y) => (y.locationName ?? '').toLowerCase().contains(dest))
          .toList();
    }
    if (name.isNotEmpty) {
      list = list.where((y) => y.name.toLowerCase().contains(name)).toList();
    }
    // Capacity filter based on guests
    list = list.where((y) => y.capacity >= _guests).toList();

    // Type filter based on category (sailing, motor, catamaran)
    if (_selectedType != 'All') {
      final sailingIds = _categories
          .where((c) => c.name.toLowerCase().contains('sail'))
          .map((c) => c.categoryId)
          .toSet();
      final motorIds = _categories
          .where((c) => c.name.toLowerCase().contains('motor'))
          .map((c) => c.categoryId)
          .toSet();
      final catamaranIds = _categories
          .where((c) => c.name.toLowerCase().contains('catamaran'))
          .map((c) => c.categoryId)
          .toSet();

      Set<int> allowed;
      switch (_selectedType) {
        case 'Sailing':
          allowed = sailingIds;
          break;
        case 'Motor':
          allowed = motorIds;
          break;
        case 'Catamaran':
          allowed = catamaranIds;
          break;
        default:
          allowed = {};
      }
      if (allowed.isNotEmpty) {
        list = list.where((y) => allowed.contains(y.categoryId)).toList();
      }
    }

    // Favorites-only mode (Favorites tab)
    if (widget.showOnlyFavorites) {
      list = list.where((y) => _favoriteIds.contains(y.yachtId)).toList();
    }

    // Sort by price
    list.sort((a, b) =>
        _sortAscending ? a.pricePerDay.compareTo(b.pricePerDay) : b.pricePerDay.compareTo(a.pricePerDay));

    setState(() {
      _filteredYachts = list;
    });
  }

  Future<void> _pickDates() async {
    final now = DateTime.now();
    final initial = _dateRange ??
        DateTimeRange(
          start: now.add(const Duration(days: 1)),
          end: now.add(const Duration(days: 4)),
        );
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (ctx) => CustomDateRangePickerDialog(
        initialRange: initial,
        firstDate: now,
        lastDate: now.add(const Duration(days: 365)),
      ),
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _pickGuests() async {
    final options = [1, 2, 4, 6, 8, 10, 12];
    final selected = await showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'How many guests?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ...options.map((g) => ListTile(
                  title: Text('$g guest${g > 1 ? 's' : ''}'),
                  onTap: () => Navigator.of(ctx).pop(g),
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() => _guests = selected);
      _applyFilters();
    }
  }

  Future<void> _toggleFavorite(int yachtId, bool makeFavorite) async {
    setState(() {
      if (makeFavorite) {
        _favoriteIds.add(yachtId);
      } else {
        _favoriteIds.remove(yachtId);
      }
    });
    await FavoritesService.saveFavorites(widget.user.userId, _favoriteIds);
  }

  Future<void> _openFilterSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Yacht type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            RadioListTile<String>(
              value: 'All',
              groupValue: _selectedType,
              title: const Text('All types'),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            RadioListTile<String>(
              value: 'Sailing',
              groupValue: _selectedType,
              title: const Text('Sailing yachts'),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            RadioListTile<String>(
              value: 'Motor',
              groupValue: _selectedType,
              title: const Text('Motor yachts'),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            RadioListTile<String>(
              value: 'Catamaran',
              groupValue: _selectedType,
              title: const Text('Catamarans'),
              onChanged: (v) => Navigator.of(ctx).pop(v),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) {
      setState(() => _selectedType = selected);
      _applyFilters();
    }
  }

  void _openYachtDetails(YachtOverview yacht) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileYachtDetailScreen(
          api: _api,
          user: widget.user,
          overview: yacht,
        ),
      ),
    );
  }
}

class _YachtCard extends StatefulWidget {
  final YachtOverview yacht;
  final ApiService api;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final bool showFavoriteIcon;
  final VoidCallback? onTap;

  const _YachtCard({
    required this.yacht,
    required this.api,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.showFavoriteIcon = true,
    this.onTap,
  });

  @override
  State<_YachtCard> createState() => _YachtCardState();
}

class _YachtCardState extends State<_YachtCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final yacht = widget.yacht;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Card(
          margin: const EdgeInsets.only(bottom: 14),
          elevation: _hovering ? 6 : 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (yacht.thumbnailImageId != null)
                    Image.network(
                      widget.api.yachtImageUrl(yacht.thumbnailImageId!),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      headers: widget.api.authHeaders,
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
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        if (yacht.locationName != null)
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined,
                                  size: 15, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                yacht.locationName!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        if (yacht.averageRating != null &&
                            yacht.reviewCount > 0)
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Color(0xFFFFC107)),
                              const SizedBox(width: 4),
                              Text(
                                yacht.averageRating!.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${yacht.reviewCount})',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        if (yacht.averageRating != null &&
                            yacht.reviewCount > 0)
                          const SizedBox(height: 6),
                        Row(
                          children: [
                            _chip(Icons.people_outline,
                                '${yacht.capacity} guests'),
                            const SizedBox(width: 8),
                            if (yacht.yearBuilt != null)
                              _chip(Icons.calendar_today_outlined,
                                  '${yacht.yearBuilt}'),
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
              if (widget.showFavoriteIcon)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(32, 32),
                    ),
                    icon: Icon(
                      widget.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.isFavorite
                          ? Colors.pinkAccent
                          : Colors.white,
                      size: 18,
                    ),
                    onPressed: widget.onToggleFavorite,
                  ),
                ),
            ],
          ),
        ),
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
