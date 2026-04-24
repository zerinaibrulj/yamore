import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/yacht_overview.dart';
import '../../models/yacht_detail.dart';
import '../../models/yacht_image.dart';
import '../../models/yacht_availability.dart';
import '../../models/service_model.dart';
import '../../models/city.dart';
import '../../models/yacht_category.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_date_range_picker_dialog.dart';

class OwnerYachtsTab extends StatefulWidget {
  final AuthService authService;
  final AppUser user;

  const OwnerYachtsTab(
      {super.key, required this.authService, required this.user});

  @override
  State<OwnerYachtsTab> createState() => _OwnerYachtsTabState();
}

class _OwnerYachtsTabState extends State<OwnerYachtsTab> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  List<YachtOverview> _yachts = [];
  bool _loading = true;
  String? _error;

  List<CityModel> _cities = [];
  List<YachtCategoryModel> _categories = [];

  int _itemsPerPage = 10;
  int _currentPage = 0;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _yachtListAnchorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  int get _totalPages {
    if (_yachts.isEmpty) return 1;
    return (_yachts.length / _itemsPerPage).ceil();
  }

  int get _effectivePage {
    final maxPage = _totalPages - 1;
    return _currentPage.clamp(0, maxPage < 0 ? 0 : maxPage);
  }

  List<YachtOverview> get _pagedYachts {
    if (_yachts.isEmpty) return const [];
    final page = _effectivePage;
    final start = page * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _yachts.length);
    return _yachts.sublist(start, end);
  }

  void _clampOwnerYachtPage() {
    if (_yachts.isEmpty) {
      _currentPage = 0;
      return;
    }
    final maxPage = _totalPages - 1;
    if (_currentPage > maxPage) _currentPage = maxPage;
  }

  void _scrollToYachtListStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _yachtListAnchorKey.currentContext;
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

  void _updateItemsPerPage(int value) {
    setState(() {
      _itemsPerPage = value;
      _currentPage = 0;
    });
    _scrollToYachtListStart();
  }

  void _goToPreviousYachtPage() {
    setState(() {
      _currentPage = (_effectivePage - 1).clamp(0, _totalPages - 1);
    });
    _scrollToYachtListStart();
  }

  void _goToNextYachtPage() {
    setState(() {
      _currentPage = (_effectivePage + 1).clamp(0, _totalPages - 1);
    });
    _scrollToYachtListStart();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getMyYachts(pageSize: 100),
        _api.getCities(),
        _api.getYachtCategories(),
      ]);
      if (mounted) {
        setState(() {
          _yachts = (results[0] as PagedYachtOverview).resultList;
          _cities = results[1] as List<CityModel>;
          _categories = results[2] as List<YachtCategoryModel>;
          _clampOwnerYachtPage();
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

  Future<void> _addYacht() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _OwnerYachtFormScreen(
          api: _api,
          ownerId: widget.user.userId,
          cities: _cities,
          categories: _categories,
          canEdit: true,
        ),
      ),
    );
    if (saved == true) await _loadAll();
  }

  Future<void> _editYacht(YachtOverview overview) async {
    final canEdit = _canEditYacht(overview.stateMachine);
    if (!canEdit) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Editing disabled'),
          content: const Text(
            'This yacht can only be edited when its status is \"Draft\" or \"Active\".',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final detail = await _api.getYachtById(overview.yachtId);
      if (!mounted) return;
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => _OwnerYachtFormScreen(
            api: _api,
            ownerId: widget.user.userId,
            cities: _cities,
            categories: _categories,
            existing: detail,
            canEdit: canEdit,
          ),
        ),
      );
      if (saved == true) await _loadAll();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load yacht details: $e')),
        );
      }
    }
  }

  Future<void> _deleteYacht(YachtOverview yacht) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.delete_forever_outlined,
                  color: Colors.red.shade600, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Delete Yacht'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${yacht.name}"?\nThis action cannot be undone.',
          style: const TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('Delete'),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteYacht(yacht.yachtId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${yacht.name}" has been deleted.'),
              backgroundColor: Colors.green.shade600,
            ),
          );
        }
        await _loadAll();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        color: AppTheme.primaryBlue,
        onRefresh: _loadAll,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1a237e), Color(0xFF3949ab)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.directions_boat,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'My Yachts',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        const Spacer(),
                        if (!_loading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_yachts.length} yacht${_yachts.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!_loading &&
                        _error == null &&
                        _yachts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 2),
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
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade700),
                                items: const [
                                  DropdownMenuItem(
                                      value: 5, child: Text('5 / page')),
                                  DropdownMenuItem(
                                      value: 10, child: Text('10 / page')),
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
                    ],
                  ],
                ),
              ),
            ),
            ..._buildSliverBodySlivers(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addYacht,
        icon: const Icon(Icons.add),
        label: const Text('Add Yacht'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  List<Widget> _buildSliverBodySlivers() {
    if (_loading) {
      return [
        const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined,
                      size: 56, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: TextStyle(color: Colors.red.shade600),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _loadAll,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ];
    }
    if (_yachts.isEmpty) {
      return [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.sailing,
                      size: 56, color: Colors.grey.shade400),
                ),
                const SizedBox(height: 16),
                Text(
                  'No yachts yet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap + Add Yacht to list your first vessel.',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    final total = _yachts.length;
    final totalPages = _totalPages;
    final current = _effectivePage;
    final from = total == 0 ? 0 : (current * _itemsPerPage) + 1;
    final to = ((current * _itemsPerPage) + _itemsPerPage).clamp(0, total);
    final paged = _pagedYachts;

    return [
      SliverPadding(
        key: _yachtListAnchorKey,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildYachtCard(paged[index]),
            childCount: paged.length,
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: current > 0 ? _goToPreviousYachtPage : null,
                      icon: const Icon(Icons.chevron_left, size: 16),
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: EdgeInsets.zero,
                      tooltip: 'Previous page',
                    ),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${current + 1}/$totalPages',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                    IconButton(
                      onPressed: current < totalPages - 1
                          ? _goToNextYachtPage
                          : null,
                      icon: const Icon(Icons.chevron_right, size: 16),
                      constraints:
                          const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: EdgeInsets.zero,
                      tooltip: 'Next page',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildYachtCard(YachtOverview yacht) {
    final stateColor = _stateColor(yacht.stateMachine);
    final stateName = yacht.stateMachine ?? 'Draft';
    final canEdit = _canEditYacht(yacht.stateMachine);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              if (yacht.thumbnailImageId != null)
                Image.network(
                  _api.yachtImageUrl(yacht.thumbnailImageId!),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  headers: _api.authHeaders,
                  errorBuilder: (_, __, ___) => _imagePlaceholder(),
                )
              else
                _imagePlaceholder(),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: stateColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: stateColor.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    stateName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 10,
                left: 14,
                child: Text(
                  yacht.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (yacht.locationName != null) ...[
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 16, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text(
                        yacht.locationName!,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statChip(Icons.people_outline, '${yacht.capacity}',
                        'Guests'),
                    const SizedBox(width: 10),
                    if (yacht.length != null)
                      _statChip(Icons.straighten,
                          '${yacht.length!.toStringAsFixed(1)}m', 'Length'),
                    if (yacht.length != null) const SizedBox(width: 10),
                    if (yacht.yearBuilt != null)
                      _statChip(Icons.calendar_today_outlined,
                          '${yacht.yearBuilt}', 'Year'),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1a237e), Color(0xFF283593)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '€${_formatPriceDisplay(yacht.pricePerDay)} / day',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: canEdit ? () => _editYacht(yacht) : null,
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.primaryBlue,
                    ),
                  ),
                ),
                Container(
                    width: 1, height: 24, color: Colors.grey.shade300),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _deleteYacht(yacht),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Delete'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F8),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 15, color: AppTheme.primaryBlue),
          ),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatPriceDisplay(double price) {
    return price.toStringAsFixed(2);
  }

  Color _stateColor(String? state) {
    switch (state?.toLowerCase()) {
      case 'active':
        return const Color(0xFF2E7D32);
      case 'draft':
        return Colors.orange.shade700;
      case 'hidden':
        return Colors.blueGrey;
      default:
        return Colors.blueGrey;
    }
  }

  bool _canEditYacht(String? stateMachine) {
    final s = (stateMachine ?? '').toLowerCase();
    return s == 'draft' || s == 'active' || s == 'activate';
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade200, Colors.grey.shade100],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sailing, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 6),
          Text('No image',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ],
      ),
    );
  }
}

class _OwnerYachtFormScreen extends StatefulWidget {
  final ApiService api;
  final int ownerId;
  final List<CityModel> cities;
  final List<YachtCategoryModel> categories;
  final YachtDetail? existing;
  final bool canEdit;

  const _OwnerYachtFormScreen({
    required this.api,
    required this.ownerId,
    required this.cities,
    required this.categories,
    this.existing,
    required this.canEdit,
  });

  @override
  State<_OwnerYachtFormScreen> createState() => _OwnerYachtFormScreenState();
}

class _OwnerYachtFormScreenState extends State<_OwnerYachtFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _length;
  late final TextEditingController _price;
  late final TextEditingController _description;
  int? _yearBuilt;
  int? _capacity;
  int? _cabins;
  int? _bathrooms;
  int? _locationId;
  int? _categoryId;
  bool _saving = false;

  List<YachtImageModel> _images = [];
  bool _imagesLoading = false;
  bool _imageUploading = false;

  List<YachtAvailability> _availabilities = [];
  bool _availLoading = false;

  List<ServiceModel> _allServices = [];
  Set<int> _assignedServiceIds = {};
  bool _servicesLoading = false;

  bool get _isEdit => widget.existing != null;

  bool get _canEdit => widget.canEdit;
  bool get _readOnly => !_canEdit;

  Future<void> _showEditingDisabledDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editing disabled'),
        content: const Text(
          'This yacht cannot be edited in its current state. Only "Draft" and "Active" yachts can be edited.',
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

  Future<void> _showInvalidDataDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invalid data'),
        content: const Text(
          'Please enter valid data in all required fields before creating or saving the yacht.',
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

  Future<void> _showSuccessActionDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static String _formatPriceForEdit(double value) {
    if (value == value.truncateToDouble()) return value.toInt().toString();
    return value.toString();
  }

  @override
  void initState() {
    super.initState();
    final y = widget.existing;
    _name = TextEditingController(text: y?.name ?? '');
    _yearBuilt = y?.yearBuilt;
    _length = TextEditingController(text: y != null ? y.length.toString() : '');
    _capacity = y?.capacity;
    _cabins = y?.cabins;
    _bathrooms = y?.bathrooms;
    _price = TextEditingController(
        text: y != null ? _formatPriceForEdit(y.pricePerDay) : '');
    _description = TextEditingController(text: y?.description ?? '');
    _locationId = y?.locationId;
    _categoryId = y?.categoryId;

    if (_isEdit) {
      _loadImages();
      _loadAvailabilities();
      _loadServices();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _length.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    setState(() => _imagesLoading = true);
    try {
      final imgs = await widget.api.getYachtImages(widget.existing!.yachtId!);
      if (mounted) setState(() => _images = imgs);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load yacht images: $e')),
        );
      }
    }
    if (mounted) setState(() => _imagesLoading = false);
  }

  Future<void> _pickAndUploadImage() async {
    if (!_canEdit) {
      await _showEditingDisabledDialog();
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.single.path;
    if (path == null) return;

    setState(() => _imageUploading = true);
    final countBefore = _images.length;
    try {
      await widget.api.uploadYachtImage(widget.existing!.yachtId!, path);
      await _loadImages();
      if (mounted) {
        await _showSuccessActionDialog(
          title: 'Image added',
          message: 'The image has been added successfully.',
        );
        setState(() => _imageUploading = false);
      }
    } catch (e) {
      debugPrint('Image upload reported an error: $e');
      await _loadImages();
      if (mounted) {
        if (_images.length > countBefore) {
          await _showSuccessActionDialog(
            title: 'Image added',
            message: 'The image has been added successfully.',
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Upload failed. Please try again.')),
          );
        }
        setState(() => _imageUploading = false);
      }
    }
  }

  Future<void> _deleteImage(YachtImageModel img) async {
    if (!_canEdit) {
      await _showEditingDisabledDialog();
      return;
    }
    try {
      await widget.api.deleteYachtImage(img.yachtImageId);
      await _loadImages();
      if (mounted) {
        await _showSuccessActionDialog(
          title: 'Image deleted',
          message: 'The image has been deleted successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete image: $e')),
        );
      }
    }
  }

  Future<void> _setThumbnail(YachtImageModel img) async {
    if (!_canEdit) {
      await _showEditingDisabledDialog();
      return;
    }
    try {
      await widget.api.setYachtImageThumbnail(img.yachtImageId);
      await _loadImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover image updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set cover image: $e')),
        );
      }
    }
  }

  Future<void> _loadAvailabilities() async {
    setState(() => _availLoading = true);
    try {
      final result = await widget.api.getYachtAvailabilities(
        yachtId: widget.existing!.yachtId!,
        pageSize: 50,
      );
      if (mounted) setState(() => _availabilities = result.resultList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load availability periods: $e')),
        );
      }
    }
    if (mounted) setState(() => _availLoading = false);
  }

  Future<void> _addAvailability() async {
    if (!_canEdit) {
      await _showEditingDisabledDialog();
      return;
    }
    DateTimeRange? range;
    bool isBlocked = true;
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(children: const [
            Icon(Icons.event_available_outlined, size: 22),
            SizedBox(width: 8),
            Text('Add Availability Period'),
          ]),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final initial = range ??
                        DateTimeRange(
                          start: now.add(const Duration(days: 1)),
                          end: now.add(const Duration(days: 4)),
                        );
                    final picked = await showDialog<DateTimeRange>(
                      context: ctx,
                      builder: (_) => CustomDateRangePickerDialog(
                        initialRange: initial,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: now.add(const Duration(days: 730)),
                      ),
                    );
                    if (picked != null) setLocal(() => range = picked);
                  },
                  icon:
                      const Icon(Icons.calendar_month_outlined, size: 18),
                  label: Text(
                    range == null
                        ? 'Select date range'
                        : '${_fmtDate(range!.start)} – ${_fmtDate(range!.end)}',
                    style: TextStyle(
                        fontWeight: range != null
                            ? FontWeight.w600
                            : FontWeight.w400),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Block period (unavailable)'),
                  subtitle: Text(
                    isBlocked
                        ? 'Yacht will be unavailable during this period'
                        : 'Yacht will be available during this period',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: isBlocked,
                  onChanged: (v) => setLocal(() => isBlocked = v),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton.icon(
              onPressed:
                  range == null ? null : () => Navigator.pop(ctx, true),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && range != null) {
      try {
        await widget.api.insertYachtAvailability(
          yachtId: widget.existing!.yachtId!,
          startDate: range!.start,
          endDate: range!.end,
          isBlocked: isBlocked,
          note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        );
        await _loadAvailabilities();
        if (mounted) {
          await _showSuccessActionDialog(
            title: isBlocked
                ? 'Unavailable period added'
                : 'Available period added',
            message: isBlocked
                ? 'The yacht has been marked as unavailable for the selected period.'
                : 'The yacht has been marked as available for the selected period.',
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add availability: $e')),
          );
        }
      }
    }
    noteCtrl.dispose();
  }

  Future<void> _deleteAvailability(YachtAvailability a) async {
    if (!_canEdit) {
      await _showEditingDisabledDialog();
      return;
    }
    try {
      await widget.api.deleteYachtAvailability(a.yachtAvailabilityId);
      await _loadAvailabilities();
      if (mounted) {
        await _showSuccessActionDialog(
          title: 'Availability removed',
          message:
              'The selected availability period has been removed successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete availability period: $e')),
        );
      }
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  Future<void> _loadServices() async {
    setState(() => _servicesLoading = true);
    try {
      final results = await Future.wait([
        widget.api.getServices(pageSize: 200),
        widget.api.getYachtServiceIds(widget.existing!.yachtId!),
      ]);
      if (mounted) {
        setState(() {
          _allServices = (results[0] as PagedServices).resultList;
          _assignedServiceIds = (results[1] as List<int>).toSet();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load yacht services: $e')),
        );
      }
    }
    if (mounted) setState(() => _servicesLoading = false);
  }

  Future<void> _toggleService(int serviceId, bool assign) async {
    final yachtId = widget.existing!.yachtId!;
    try {
      if (assign) {
        await widget.api.assignYachtService(yachtId: yachtId, serviceId: serviceId);
        if (mounted) setState(() => _assignedServiceIds.add(serviceId));
      } else {
        await widget.api.removeYachtService(yachtId: yachtId, serviceId: serviceId);
        if (mounted) setState(() => _assignedServiceIds.remove(serviceId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_canEdit) {
      await _showEditingDisabledDialog();
      return;
    }
    if (!_formKey.currentState!.validate()) {
      await _showInvalidDataDialog();
      return;
    }
    setState(() => _saving = true);

    final detail = YachtDetail(
      yachtId: widget.existing?.yachtId,
      ownerId: widget.ownerId,
      name: _name.text.trim(),
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
      yearBuilt: _yearBuilt!,
      length: double.parse(_length.text),
      capacity: _capacity!,
      cabins: _cabins!,
      bathrooms: _bathrooms,
      pricePerDay: double.parse(_price.text),
      locationId: _locationId!,
      categoryId: _categoryId!,
      isActive: true,
    );

    try {
      if (_isEdit) {
        await widget.api.updateYacht(detail);
      } else {
        await widget.api.createYacht(detail);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit ? 'Yacht updated!' : 'Yacht created!'),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${e.displayMessage}')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEdit ? (_readOnly ? 'Yacht (View)' : 'Edit Yacht') : 'New Yacht',
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_readOnly)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _saving
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Save'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        foregroundColor: Colors.white,
                      ),
                    ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader(Icons.info_outline, 'Basic Information'),
              const SizedBox(height: 12),
              _card([
                TextFormField(
                  controller: _name,
                  enabled: !_readOnly,
                  decoration: _inputDeco('Yacht Name',
                      icon: Icons.directions_boat_outlined,
                      isValid: _isNameValid,
                      value: _name.text),
                  onChanged: (_) => setState(() {}),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _description,
                  enabled: !_readOnly,
                  decoration: _inputDeco('Description (optional)',
                      icon: Icons.notes_outlined),
                  maxLines: 3,
                ),
              ]),

              const SizedBox(height: 20),

              _sectionHeader(Icons.build_outlined, 'Specifications'),
              const SizedBox(height: 12),
              _card([
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _yearBuilt,
                      decoration:
                          _inputDeco('Year',
                              icon: Icons.calendar_today,
                              isValid: _yearBuilt != null,
                              value: _yearBuilt?.toString() ?? ''),
                      items: List<int>.generate(
                              40, (i) => DateTime.now().year - i)
                          .map((y) =>
                              DropdownMenuItem(value: y, child: Text('$y')))
                          .toList(),
                      onChanged: _readOnly ? null : (v) => setState(() => _yearBuilt = v),
                      validator: (v) => v == null ? 'Year' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _length,
                      enabled: !_readOnly,
                      decoration:
                          _inputDeco('Length (m)',
                              icon: Icons.straighten,
                              isValid: _isLengthValid,
                              value: _length.text),
                      onChanged: (_) => setState(() {}),
                      keyboardType: TextInputType.number,
                      validator: (v) =>
                          double.tryParse(v ?? '') == null ? 'Length' : null,
                    ),
                  ),
                ]),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _capacity,
                      decoration:
                          _inputDeco('Capacity',
                              icon: Icons.people_outline,
                              isValid: _capacity != null,
                              value: _capacity?.toString() ?? ''),
                      items: List.generate(30, (i) => i + 1)
                          .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text('$n guest${n > 1 ? 's' : ''}')))
                          .toList(),
                      onChanged: _readOnly ? null : (v) => setState(() => _capacity = v),
                      validator: (v) => v == null ? 'Capacity' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _cabins,
                      decoration: _inputDeco('Cabins',
                          icon: Icons.king_bed_outlined,
                          isValid: _cabins != null,
                          value: _cabins?.toString() ?? ''),
                      items: List.generate(15, (i) => i + 1)
                          .map((n) => DropdownMenuItem(
                              value: n,
                              child: Text('$n cabin${n > 1 ? 's' : ''}')))
                          .toList(),
                      onChanged: _readOnly ? null : (v) => setState(() => _cabins = v),
                      validator: (v) => v == null ? 'Cabins' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _bathrooms,
                      decoration: _inputDeco('Bathrooms',
                          icon: Icons.bathtub_outlined,
                          isValid: _bathrooms != null,
                          value: _bathrooms?.toString() ?? ''),
                      items: [
                        const DropdownMenuItem<int>(
                            value: null, child: Text('N/A')),
                        ...List.generate(10, (i) => i + 1).map((n) =>
                            DropdownMenuItem(value: n, child: Text('$n'))),
                      ],
                      onChanged: _readOnly ? null : (v) => setState(() => _bathrooms = v),
                    ),
                  ),
                ]),
              ]),

              const SizedBox(height: 20),

              _sectionHeader(Icons.euro_outlined, 'Pricing & Location'),
              const SizedBox(height: 12),
              _card([
                TextFormField(
                  controller: _price,
                  enabled: !_readOnly,
                  decoration:
                      _inputDeco('Price (€/day)',
                          icon: Icons.euro,
                          isValid: _isPriceValid,
                          value: _price.text),
                  onChanged: (_) => setState(() {}),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  validator: (v) =>
                      double.tryParse(v ?? '') == null ? 'Price' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _locationId,
                  decoration: _inputDeco('Location',
                      icon: Icons.location_on_outlined,
                      isValid: _locationId != null,
                      value: _locationId?.toString() ?? ''),
                  items: widget.cities
                      .map((c) => DropdownMenuItem(
                          value: c.cityId, child: Text(c.name)))
                      .toList(),
                  onChanged: _readOnly ? null : (v) => setState(() => _locationId = v),
                  validator: (v) => v == null ? 'Select location' : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _categoryId,
                  decoration: _inputDeco('Category',
                      icon: Icons.category_outlined,
                      isValid: _categoryId != null,
                      value: _categoryId?.toString() ?? ''),
                  items: widget.categories
                      .map((c) => DropdownMenuItem(
                          value: c.categoryId, child: Text(c.name)))
                      .toList(),
                  onChanged: _readOnly ? null : (v) => setState(() => _categoryId = v),
                  validator: (v) => v == null ? 'Select category' : null,
                ),
              ]),

              if (_isEdit) ...[
                const SizedBox(height: 20),
                _sectionHeader(Icons.photo_library_outlined, 'Photos'),
                const SizedBox(height: 12),
                _card([
                  Row(children: [
                    Text(
                      '${_images.length} photo${_images.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: (_readOnly || _imageUploading)
                          ? null
                          : _pickAndUploadImage,
                      icon: _imageUploading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.add_photo_alternate_outlined,
                              size: 18),
                      label:
                          Text(_imageUploading ? 'Uploading...' : 'Add Photo'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (_imagesLoading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ))
                  else if (_images.isEmpty)
                    Container(
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_outlined,
                              size: 32, color: Colors.grey.shade400),
                          const SizedBox(height: 4),
                          Text('No photos yet',
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                        ],
                      ),
                    )
                  else
                    SizedBox(
                      height: 140,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, i) =>
                            _buildImageTile(_images[i]),
                      ),
                    ),
                ]),
              ],

              if (_isEdit) ...[
                const SizedBox(height: 20),
                _sectionHeader(
                    Icons.event_available_outlined, 'Availability'),
                const SizedBox(height: 12),
                _card([
                  Row(children: [
                    Text(
                      '${_availabilities.length} period${_availabilities.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _readOnly ? null : _addAvailability,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Period'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  if (_availLoading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator()))
                  else if (_availabilities.isEmpty)
                    Container(
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Text('No availability periods set.',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    )
                  else
                    ...(_availabilities.map((a) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: a.isBlocked
                                  ? Colors.red.shade200
                                  : Colors.green.shade200,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            color: a.isBlocked
                                ? Colors.red.shade50.withOpacity(0.5)
                                : Colors.green.shade50.withOpacity(0.5),
                          ),
                          child: ListTile(
                            dense: true,
                            leading: Icon(
                              a.isBlocked
                                  ? Icons.block
                                  : Icons.check_circle_outline,
                              color:
                                  a.isBlocked ? Colors.red : Colors.green,
                              size: 22,
                            ),
                            title: Text(
                              '${_fmtDate(a.startDate)} – ${_fmtDate(a.endDate)}',
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${a.isBlocked ? 'Blocked' : 'Available'}${a.note != null && a.note!.isNotEmpty ? ' · ${a.note}' : ''}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.redAccent),
                              tooltip: 'Remove',
                              onPressed: _readOnly ? null : () => _deleteAvailability(a),
                            ),
                          ),
                        ))),
                ]),
              ],

              if (_isEdit) ...[
                const SizedBox(height: 20),
                _sectionHeader(Icons.room_service_outlined, 'Services Offered'),
                const SizedBox(height: 12),
                _card([
                  Text(
                    'Toggle the services this yacht offers. Guests will see these when booking.',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  if (_servicesLoading)
                    const Center(
                        child: Padding(
                            padding: EdgeInsets.all(20),
                            child: CircularProgressIndicator()))
                  else if (_allServices.isEmpty)
                    Container(
                      height: 70,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade50,
                      ),
                      child: Text('No services available on the platform.',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    )
                  else
                    ..._allServices.map((svc) {
                      final assigned = _assignedServiceIds.contains(svc.serviceId);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: assigned
                                ? AppTheme.primaryBlue.withOpacity(0.4)
                                : Colors.grey.shade300,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          color: assigned
                              ? AppTheme.primaryBlue.withOpacity(0.04)
                              : Colors.white,
                        ),
                        child: SwitchListTile(
                          dense: true,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          secondary: Icon(
                            _serviceIcon(svc.name),
                            color: assigned
                                ? AppTheme.primaryBlue
                                : Colors.grey.shade400,
                            size: 22,
                          ),
                          title: Text(
                            svc.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  assigned ? FontWeight.w600 : FontWeight.w400,
                              color: assigned
                                  ? AppTheme.primaryBlue
                                  : Colors.grey.shade700,
                            ),
                          ),
                          subtitle: svc.price != null
                              ? Text(
                                  '€${svc.price!.toStringAsFixed(0)}/booking',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500),
                                )
                              : null,
                          value: assigned,
                          activeColor: AppTheme.primaryBlue,
                          onChanged: _readOnly
                              ? null
                              : (val) => _toggleService(svc.serviceId, val),
                        ),
                      );
                    }),
                ]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _serviceIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('skipper') || n.contains('captain')) return Icons.person;
    if (n.contains('cater') || n.contains('food') || n.contains('chef')) return Icons.restaurant;
    if (n.contains('diving') || n.contains('snorkel')) return Icons.scuba_diving;
    if (n.contains('wifi') || n.contains('internet')) return Icons.wifi;
    if (n.contains('music') || n.contains('dj') || n.contains('entertainment')) return Icons.music_note;
    if (n.contains('clean') || n.contains('laundry')) return Icons.cleaning_services;
    if (n.contains('fuel') || n.contains('gas')) return Icons.local_gas_station;
    if (n.contains('equip') || n.contains('gear')) return Icons.fitness_center;
    if (n.contains('transfer') || n.contains('transport')) return Icons.directions_car;
    if (n.contains('fishing')) return Icons.phishing;
    if (n.contains('photo') || n.contains('video')) return Icons.camera_alt;
    if (n.contains('drink') || n.contains('bar') || n.contains('beverage')) return Icons.local_bar;
    if (n.contains('towel') || n.contains('linen')) return Icons.dry_cleaning;
    if (n.contains('insurance') || n.contains('safety')) return Icons.health_and_safety;
    return Icons.room_service_outlined;
  }

  Widget _sectionHeader(IconData icon, String title) {
    return Row(children: [
      Icon(icon, size: 20, color: AppTheme.primaryBlue),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _card(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  bool get _isNameValid {
    final value = _name.text.trim();
    return value.isNotEmpty && value.length <= 100;
  }

  bool get _isLengthValid => double.tryParse(_length.text.trim()) != null;

  bool get _isPriceValid => double.tryParse(_price.text.trim()) != null;

  Widget? _buildValidationIcon(bool isValid, String value) {
    if (value.trim().isEmpty) return null;
    return SizedBox(
      width: 24,
      child: Align(
        alignment: Alignment.center,
        child: Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red.shade400,
          size: 18,
        ),
      ),
    );
  }

  InputDecoration _inputDeco(
    String label, {
    IconData? icon,
    bool? isValid,
    String value = '',
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      suffixIcon: isValid == null ? null : _buildValidationIcon(isValid, value),
      suffixIconConstraints:
          const BoxConstraints(minWidth: 30, minHeight: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      filled: true,
      fillColor: const Color(0xFFFAFBFD),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _buildImageTile(YachtImageModel img) {
    final url = widget.api.yachtImageUrl(img.yachtImageId);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            width: 150,
            height: 140,
            fit: BoxFit.cover,
            headers: widget.api.authHeaders,
            errorBuilder: (_, __, ___) => Container(
              width: 150,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  const Icon(Icons.broken_image, size: 28, color: Colors.grey),
            ),
          ),
        ),
        if (img.isThumbnail)
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('Cover',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        Positioned(
          top: 6,
          right: 6,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!img.isThumbnail)
                _miniBtn(
                  Icons.star_outline,
                  _readOnly ? null : () => _setThumbnail(img),
                ),
              const SizedBox(height: 3),
              _miniBtn(
                Icons.delete_outline,
                _readOnly ? null : () => _deleteImage(img),
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniBtn(
    IconData icon,
    VoidCallback? onTap, {
    Color color = Colors.white,
  }) {
    final enabled = onTap != null;
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(
              icon,
              size: 16,
              color: enabled ? color : color.withOpacity(0.45),
            )),
      ),
    );
  }
}
