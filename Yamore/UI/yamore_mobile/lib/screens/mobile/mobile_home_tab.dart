import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/favorites_service.dart';
import '../../models/yacht_overview.dart';
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
    auth: widget.authService,
  );

  List<YachtOverview> _allYachts = [];
  List<YachtOverview> _filteredYachts = [];
  List<YachtOverview> _recommended = [];
  List<YachtCategoryModel> _categories = [];
  bool _loading = true;
  String? _error;

  final TextEditingController _destinationCtrl = TextEditingController();
  final TextEditingController _searchNameCtrl = TextEditingController();
  DateTimeRange? _dateRange;
  int _guests = 2;
  Set<int> _favoriteIds = {};
  String _selectedType = 'All'; // All, Sailing, Motor, Catamaran
  bool _sortAscending = true;
  int _itemsPerPage = 10;
  int _currentPage = 0;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _yachtListHeaderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// After changing the yacht list page, scroll so the list (first yacht on the new page) is in view.
  void _scrollToYachtListStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _yachtListHeaderKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: Duration.zero,
          alignment: 0,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant MobileHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.userId != widget.user.userId) {
      _loadInitial();
      return;
    }
    if (oldWidget.showOnlyFavorites != widget.showOnlyFavorites) {
      _applyFilters();
    }
  }

  /// Favorites are stored by id, but the overview API returns a capped, filtered page.
  /// Load any saved favorite not present in [apiList] so they still appear after restart.
  Future<List<YachtOverview>> _mergeFavoriteYachtsFromDetail(
    List<YachtOverview> apiList,
    Set<int> favoriteIds,
  ) async {
    if (favoriteIds.isEmpty) return apiList;
    final have = apiList.map((y) => y.yachtId).toSet();
    final missing = favoriteIds.difference(have);
    if (missing.isEmpty) return apiList;
    final extras = <YachtOverview>[];
    for (final id in missing) {
      try {
        final d = await _api.getYachtById(id);
        if (d.yachtId != null) {
          extras.add(YachtOverview.fromYachtDetail(d));
        }
      } catch (e) {
        debugPrint('Failed to load favorite yacht detail $id: $e');
      }
    }
    if (extras.isEmpty) return apiList;
    return [...apiList, ...extras];
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final favs = await FavoritesService.loadFavorites(widget.user.userId);
    try {
      final results = await Future.wait([
        _api.getYachtOverviewForAdmin(
          pageSize: 100,
          capacityMin: _guests,
          availableFrom: _dateRange?.start,
          availableTo: _dateRange?.end,
        ),
        _api.getYachtCategories(),
        _api.getRecommendations(pageSize: 10),
      ]);
      final overview = results[0] as PagedYachtOverview;
      final cats = results[1] as List<YachtCategoryModel>;
      final recPage = results[2] as PagedYachtOverview;
      final merged =
          await _mergeFavoriteYachtsFromDetail(overview.resultList, favs);
      if (mounted) {
        setState(() {
          _allYachts = merged;
          _categories = cats;
          _favoriteIds = {...favs};
          _recommended = recPage.resultList.isNotEmpty
              ? recPage.resultList
              : _fallbackRecommended(merged);
          _applyFilters();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _favoriteIds = {...favs};
          _recommended = [];
          _error = 'Failed to load yachts: $e';
          _loading = false;
        });
      }
    }
  }

  /// Fallback when recommendation API returns empty (e.g. new user): show popular/featured by price.
  List<YachtOverview> _fallbackRecommended(List<YachtOverview> all) {
    final sorted = [...all]..sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
    return sorted.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pagedYachts = _pagedYachts;
    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHero()),
          if (!widget.showOnlyFavorites && _recommended.isNotEmpty)
            SliverToBoxAdapter(child: _buildRecommendedStrip()),
          const SliverToBoxAdapter(child: SizedBox(height: 6)),
          SliverToBoxAdapter(
            key: _yachtListHeaderKey,
            child: _buildListHeader(),
          ),
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
                    final yacht = pagedYachts[index];
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
                  childCount: pagedYachts.length,
                ),
              ),
            ),
          if (!_loading && _error == null && _filteredYachts.isNotEmpty)
            SliverToBoxAdapter(
              child: _buildPaginationControls(),
            ),
        ],
      ),
    );
  }

  void _toggleSortOrder() {
    setState(() => _sortAscending = !_sortAscending);
  }

  void _updateItemsPerPage(int value) {
    setState(() {
      _itemsPerPage = value;
      _currentPage = 0;
    });
    _scrollToYachtListStart();
  }

  void _setFilteredYachts(List<YachtOverview> list) {
    setState(() {
      _filteredYachts = list;
      _currentPage = 0;
    });
  }

  void _goToPreviousPage() {
    setState(() => _currentPage = _currentPage - 1);
    _scrollToYachtListStart();
  }

  void _goToNextPage() {
    setState(() => _currentPage = _currentPage + 1);
    _scrollToYachtListStart();
  }

  void _setDateRange(DateTimeRange picked) {
    setState(() => _dateRange = picked);
  }

  void _setGuests(int selected) {
    setState(() => _guests = selected);
  }

  void _setSelectedType(String selected) {
    setState(() => _selectedType = selected);
  }

  void _setFavorite(int yachtId, bool makeFavorite) {
    setState(() {
      if (makeFavorite) {
        _favoriteIds.add(yachtId);
      } else {
        _favoriteIds.remove(yachtId);
      }
    });
  }

  void _revertFavoriteIds(Set<int> before) {
    if (!mounted) return;
    setState(() {
      _favoriteIds = before;
    });
  }
}

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
      padding: const EdgeInsets.fromLTRB(20, 12, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended for you',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 184,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommended.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final y = _recommended[index];
                return Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: SizedBox(
                    width: 220,
                    child: _YachtCard(
                      yacht: y,
                      api: _api,
                      isFavorite: false,
                      onToggleFavorite: () {},
                      showFavoriteIcon: false,
                      compact: true,
                      onTap: () => _openYachtDetails(y),
                    ),
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
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
                  _toggleSortOrder();
                  _applyFilters();
                },
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 / page')),
                      DropdownMenuItem(value: 10, child: Text('10 / page')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      _updateItemsPerPage(v);
                    },
                  ),
                ),
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

  void _applyFilters() {
    if (widget.showOnlyFavorites) {
      var list =
          _allYachts.where((y) => _favoriteIds.contains(y.yachtId)).toList();
      final name = _searchNameCtrl.text.trim().toLowerCase();
      if (name.isNotEmpty) {
        list = list.where((y) => y.name.toLowerCase().contains(name)).toList();
      }
      list.sort((a, b) => _sortAscending
          ? a.pricePerDay.compareTo(b.pricePerDay)
          : b.pricePerDay.compareTo(a.pricePerDay));
      _setFilteredYachts(list);
      return;
    }

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
    list = list.where((y) => y.capacity >= _guests).toList();

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

    list.sort((a, b) =>
        _sortAscending ? a.pricePerDay.compareTo(b.pricePerDay) : b.pricePerDay.compareTo(a.pricePerDay));

    _setFilteredYachts(list);
  }

  int get _totalPages {
    if (_filteredYachts.isEmpty) return 1;
    return (_filteredYachts.length / _itemsPerPage).ceil();
  }

  List<YachtOverview> get _pagedYachts {
    if (_filteredYachts.isEmpty) return const [];
    final safePage = _currentPage.clamp(0, _totalPages - 1);
    final start = safePage * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredYachts.length);
    return _filteredYachts.sublist(start, end);
  }

  Widget _buildPaginationControls() {
    final total = _filteredYachts.length;
    final totalPages = _totalPages;
    final current = _currentPage.clamp(0, totalPages - 1);
    final from = total == 0 ? 0 : (current * _itemsPerPage) + 1;
    final to = ((current * _itemsPerPage) + _itemsPerPage).clamp(0, total);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 8,
        children: [
          Text(
            'Showing $from-$to of $total',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
          Container(
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
                  onPressed: current > 0 ? _goToPreviousPage : null,
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
                    '${current + 1}/$totalPages',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
                  ),
                ),
                IconButton(
                  onPressed: current < totalPages - 1 ? _goToNextPage : null,
                  icon: const Icon(Icons.chevron_right, size: 16),
                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                  padding: EdgeInsets.zero,
                  tooltip: 'Next page',
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
      _setDateRange(picked);
      await _loadInitial();
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
      _setGuests(selected);
      await _loadInitial();
    }
  }

  Future<void> _toggleFavorite(int yachtId, bool makeFavorite) async {
    final before = Set<int>.from(_favoriteIds);
    _setFavorite(yachtId, makeFavorite);
    try {
      await FavoritesService.saveFavorites(widget.user.userId, _favoriteIds);
      if (!mounted) return;
      _applyFilters();
      if (makeFavorite) {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: Icon(Icons.favorite, color: AppTheme.primaryBlue, size: 32),
            title: const Text('Added to favorites'),
            content: const Text(
              'This yacht has been successfully added to your favorites.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: Icon(Icons.favorite_border, color: Colors.grey.shade700, size: 32),
            title: const Text('Removed from favorites'),
            content: const Text(
              'This yacht has been removed from your favorites.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _revertFavoriteIds(before);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorites: $e')),
        );
      }
    }
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
      _setSelectedType(selected);
      _applyFilters();
    }
  }

  void _openYachtDetails(YachtOverview yacht) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MobileYachtDetailScreen(
          api: _api,
          user: widget.user,
          authService: widget.authService,
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
  /// Shorter card for horizontal "Recommended" strip (avoids vertical overflow).
  final bool compact;
  final VoidCallback? onTap;

  const _YachtCard({
    required this.yacht,
    required this.api,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.showFavoriteIcon = true,
    this.compact = false,
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
    final compact = widget.compact;
    final imageHeight = compact ? 112.0 : 180.0;
    final contentPadding = compact ? 0.0 : 14.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: InkWell(
        onTap: widget.onTap,
        child: Card(
          margin: compact
              ? EdgeInsets.zero
              : const EdgeInsets.only(bottom: 14),
          elevation: _hovering ? 6 : 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (yacht.thumbnailImageId != null)
                    Image.network(
                      widget.api.yachtImageUrl(yacht.thumbnailImageId!),
                      height: imageHeight,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      headers: widget.api.authHeaders,
                      errorBuilder: (_, __, ___) =>
                          _placeholderImage(height: imageHeight),
                    )
                  else
                    _placeholderImage(height: imageHeight),
                  Padding(
                    padding: compact
                        ? const EdgeInsets.fromLTRB(8, 6, 8, 6)
                        : EdgeInsets.all(contentPadding),
                    child: compact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                yacht.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.15,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '€${yacht.pricePerDay.toStringAsFixed(2)}/day',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1a237e),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                yacht.name,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              if (yacht.locationName != null)
                                Row(
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        size: 15,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        yacht.locationName!,
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 6),
                              if (yacht.averageRating != null &&
                                  yacht.reviewCount > 0)
                                Row(
                                  children: [
                                    const Icon(Icons.star,
                                        size: 16,
                                        color: Color(0xFFFFC107)),
                                    const SizedBox(width: 4),
                                    Text(
                                      yacht.averageRating!
                                          .toStringAsFixed(1),
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
                                    '€${yacht.pricePerDay.toStringAsFixed(2)}/day',
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

  static Widget _placeholderImage({double height = 180}) {
    return Container(
      height: height,
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
