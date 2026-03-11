import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../theme/app_theme.dart';
import '../../models/yacht_overview.dart';
import '../../models/yacht_detail.dart';
import '../../models/yacht_image.dart';
import '../../models/city.dart';
import '../../models/yacht_category.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class YachtReviewScreen extends StatefulWidget {
  final AuthService authService;

  const YachtReviewScreen({super.key, required this.authService});

  @override
  State<YachtReviewScreen> createState() => _YachtReviewScreenState();
}

class _YachtReviewScreenState extends State<YachtReviewScreen> {
  late final ApiService _api = ApiService(
    baseUrl: authService.baseUrl,
    username: authService.username,
    password: authService.password,
  );

  AuthService get authService => widget.authService;

  List<YachtOverview> _yachts = [];
  int? _totalCount;
  bool _loading = true;
  String? _error;

  // lookups
  List<CityModel> _cities = [];
  List<YachtCategoryModel> _categories = [];
  List<AppUser> _owners = [];

  // filters
  final TextEditingController _searchNameController = TextEditingController();
  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();
  int? _selectedSearchLocationId;

  // selection
  int? _selectedYachtId;

  // paging
  int _currentPage = 0;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadLookups();
    await _loadYachts();
  }

  Future<void> _loadYachts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final name = _searchNameController.text.trim().isEmpty
          ? null
          : _searchNameController.text.trim();
      final priceMin =
          _priceMinController.text.trim().isEmpty ? null : double.tryParse(_priceMinController.text.trim());
      final priceMax =
          _priceMaxController.text.trim().isEmpty ? null : double.tryParse(_priceMaxController.text.trim());

      final paged = await _api.getYachtOverviewForAdmin(
        page: _currentPage,
        pageSize: _pageSize,
        name: name,
        locationId: _selectedSearchLocationId,
        priceMin: priceMin,
        priceMax: priceMax,
      );
      setState(() {
        _yachts = paged.resultList;
        _totalCount = paged.count;
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = '${e.statusCode}: ${e.body}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadLookups() async {
    try {
      final cities = await _api.getCities();
      final cats = await _api.getYachtCategories();
      setState(() {
        _cities = cities;
        _categories = cats;
      });
      final owners = await _api.getOwners();
      setState(() {
        _owners = owners;
      });
    } catch (_) {
      // keep working even if lookups fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_boat, color: AppTheme.primaryBlue, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Yacht review',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              FilledButton.icon(
                onPressed: _openAddYachtDialog,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Yacht'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilters(context),
          const SizedBox(height: 16),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadYachts, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_yachts.isEmpty) {
      return const Center(child: Text('No yachts found.'));
    }

    final total = _totalCount ?? _yachts.length;
    final start = total == 0 ? 0 : _currentPage * _pageSize + 1;
    final end = (_currentPage * _pageSize + _yachts.length).clamp(0, total);
    final totalPages =
        total == 0 ? 1 : ((total + _pageSize - 1) / _pageSize).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor:
                    WidgetStateProperty.all(AppTheme.primaryBlue),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                columns: const [
                  DataColumn(label: Text('No.')),
                  DataColumn(label: Text('')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('Owner')),
                  DataColumn(label: Text('Year')),
                  DataColumn(label: Text('Length')),
                  DataColumn(label: Text('Capacity')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('')),
                ],
                rows: _yachts
                    .asMap()
                    .entries
                    .map(
                      (entry) {
                        final index = entry.key;
                        final y = entry.value;
                        final displayIndex =
                            _currentPage * _pageSize + index + 1;
                        return DataRow(
                        selected: _selectedYachtId == y.yachtId,
                        onSelectChanged: (selected) {
                          setState(() {
                            _selectedYachtId =
                                selected == true ? y.yachtId : null;
                          });
                        },
                        cells: [
                          DataCell(Text('$displayIndex.')),
                          DataCell(
                            y.thumbnailImageId != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      _api.yachtImageUrl(y.thumbnailImageId!),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      headers: _api.authHeaders,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 24,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.image_outlined,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                          ),
                          DataCell(Text(y.name)),
                          DataCell(Text(y.locationName ?? '—')),
                          DataCell(Text(y.ownerName ?? '—')),
                          DataCell(Text(y.yearBuilt?.toString() ?? '—')),
                          DataCell(Text(y.length != null
                              ? '${y.length!.toStringAsFixed(2)} m'
                              : '—')),
                          DataCell(Text('${y.capacity}')),
                          DataCell(Text(_formatEuroPrice(y.pricePerDay))),
                          DataCell(
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit',
                                  onPressed: () => _openEditYachtDialog(y),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.redAccent),
                                  tooltip: 'Delete',
                                  onPressed: () => _deleteYacht(y),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    })
                    .toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    total == 0
                        ? 'No records'
                        : 'Showing $start–$end of $total',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (total > 0) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Page ${_currentPage + 1} of $totalPages',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  Text(
                    'Rows per page: $_pageSize',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () {
                            setState(() {
                              _currentPage--;
                            });
                            _loadYachts();
                          }
                        : null,
                  ),
                  const SizedBox(width: 4),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (_currentPage + 1) < totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                            });
                            _loadYachts();
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 220,
              child: TextField(
                controller: _searchNameController,
                decoration: const InputDecoration(
                  labelText: 'Search by name',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int>(
                value: _selectedSearchLocationId,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                items: [
                  const DropdownMenuItem<int>(
                    value: null,
                    child: Text('All locations'),
                  ),
                  ..._cities.map(
                    (c) => DropdownMenuItem<int>(
                      value: c.cityId,
                      child: Text(c.name),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedSearchLocationId = value;
                  });
                },
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _priceMinController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Min price (€)',
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _priceMaxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Max price (€)',
                ),
              ),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              onPressed: () {
                _currentPage = 0;
                _loadYachts();
              },
              icon: const Icon(Icons.filter_list),
              label: const Text('Apply'),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () {
                _searchNameController.clear();
                _priceMinController.clear();
                _priceMaxController.clear();
                setState(() {
                  _selectedSearchLocationId = null;
                  _currentPage = 0;
                });
                _loadYachts();
              },
              child: const Text('Clear'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAddYachtDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => YachtFormDialog(
        title: 'Add Yacht',
        api: _api,
        cities: _cities,
        categories: _categories,
        owners: _owners,
      ),
    );
    if (created == true) {
      await _loadYachts();
      if (mounted) {
        await _showSuccessDialog(
          context,
          title: 'Yacht created',
          message: 'The new yacht has been added successfully.',
        );
      }
    }
  }

  Future<void> _openEditYachtDialog(YachtOverview overview) async {
    try {
      final detail = await _api.getYachtById(overview.yachtId);
      final updated = await showDialog<bool>(
        context: context,
        builder: (context) => YachtFormDialog(
          title: 'Edit Yacht',
          api: _api,
          initial: detail,
          cities: _cities,
          categories: _categories,
          owners: _owners,
        ),
      );
      if (updated == true) {
        await _loadYachts();
        if (mounted) {
          await _showSuccessDialog(
            context,
            title: 'Yacht updated',
            message: 'The yacht has been updated successfully.',
          );
        }
      }
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load yacht: ${e.body}')),
      );
    }
  }

  Future<void> _deleteYacht(YachtOverview y) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete yacht'),
        content: Text('Are you sure you want to delete \"${y.name}\"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.deleteYacht(y.yachtId);
      await _loadYachts();
      if (mounted) {
        await _showSuccessDialog(
          context,
          title: 'Yacht deleted',
          message: 'The yacht has been deleted successfully.',
        );
      }
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: ${e.body}')),
      );
    }
  }
}

class YachtFormDialog extends StatefulWidget {
  final String title;
  final ApiService api;
  final YachtDetail? initial;
  final List<CityModel> cities;
  final List<YachtCategoryModel> categories;
  final List<AppUser> owners;

  const YachtFormDialog({
    super.key,
    required this.title,
    required this.api,
    this.initial,
    required this.cities,
    required this.categories,
    required this.owners,
  });

  @override
  State<YachtFormDialog> createState() => _YachtFormDialogState();
}

class _YachtFormDialogState extends State<YachtFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _ownerId;
  late TextEditingController _year;
  late TextEditingController _length;
  late TextEditingController _capacity;
  late TextEditingController _cabins;
  late TextEditingController _bathrooms;
  late TextEditingController _price;
  late TextEditingController _locationId;
  late TextEditingController _categoryId;
  late TextEditingController _description;

  bool _saving = false;
  AppUser? _selectedOwner;

  List<YachtImageModel> _images = [];
  bool _imagesLoading = false;
  bool _imageUploading = false;

  @override
  void initState() {
    super.initState();
    final y = widget.initial;
    _name = TextEditingController(text: y?.name ?? '');
    _ownerId = TextEditingController(text: y?.ownerId?.toString() ?? '');
    _year = TextEditingController(text: y?.yearBuilt.toString() ?? '');
    _length = TextEditingController(text: y?.length.toString() ?? '');
    _capacity = TextEditingController(text: y?.capacity.toString() ?? '');
    _cabins = TextEditingController(text: y?.cabins.toString() ?? '');
    _bathrooms = TextEditingController(text: y?.bathrooms?.toString() ?? '');
    _price = TextEditingController(text: y?.pricePerDay.toString() ?? '');
    _locationId = TextEditingController(text: y?.locationId.toString() ?? '');
    _categoryId = TextEditingController(text: y?.categoryId.toString() ?? '');
    _description = TextEditingController(text: y?.description ?? '');

    if (widget.owners.isNotEmpty) {
      if (y?.ownerId != null) {
        try {
          _selectedOwner =
              widget.owners.firstWhere((o) => o.userId == y!.ownerId);
        } catch (_) {
          _selectedOwner = widget.owners.first;
        }
      } else {
        _selectedOwner = widget.owners.first;
      }
      _ownerId.text = _selectedOwner!.userId.toString();
    }

    if (y?.yachtId != null) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    setState(() => _imagesLoading = true);
    try {
      final imgs = await widget.api.getYachtImages(widget.initial!.yachtId!);
      if (mounted) setState(() => _images = imgs);
    } catch (_) {}
    if (mounted) setState(() => _imagesLoading = false);
  }

  Future<void> _pickAndUploadImage() async {
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
      await widget.api.uploadYachtImage(widget.initial!.yachtId!, path);
    } catch (_) {
      // The POST may fail on the client side even if the server saved the
      // image (Windows desktop http quirk). We reload and check below.
    }
    await _loadImages();
    if (mounted) {
      if (_images.length > countBefore) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image uploaded successfully.'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload failed. Please try again.')),
        );
      }
      setState(() => _imageUploading = false);
    }
  }

  Future<void> _deleteImage(YachtImageModel img) async {
    try {
      await widget.api.deleteYachtImage(img.yachtImageId);
      await _loadImages();
    } catch (_) {}
  }

  Future<void> _setThumbnail(YachtImageModel img) async {
    try {
      await widget.api.setYachtImageThumbnail(img.yachtImageId);
      await _loadImages();
    } catch (_) {}
  }

  @override
  void dispose() {
    _name.dispose();
    _ownerId.dispose();
    _year.dispose();
    _length.dispose();
    _capacity.dispose();
    _cabins.dispose();
    _bathrooms.dispose();
    _price.dispose();
    _locationId.dispose();
    _categoryId.dispose();
    _description.dispose();
    super.dispose();
  }

  Widget _buildImageTile(YachtImageModel img) {
    final url = widget.api.yachtImageUrl(img.yachtImageId);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            width: 150,
            height: 130,
            fit: BoxFit.cover,
            headers: widget.api.authHeaders,
            errorBuilder: (_, __, ___) => Container(
              width: 150,
              height: 130,
              color: Colors.grey.shade200,
              child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
            ),
          ),
        ),
        if (img.isThumbnail)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Cover',
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!img.isThumbnail)
                _miniButton(
                  icon: Icons.star_outline,
                  tooltip: 'Set as cover',
                  onTap: () => _setThumbnail(img),
                ),
              const SizedBox(width: 2),
              _miniButton(
                icon: Icons.delete_outline,
                tooltip: 'Delete',
                color: Colors.red,
                onTap: () => _deleteImage(img),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _miniButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return Material(
      color: Colors.black54,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final detail = YachtDetail(
      yachtId: widget.initial?.yachtId,
      ownerId: _ownerId.text.isEmpty ? null : int.tryParse(_ownerId.text),
      name: _name.text.trim(),
      description: _description.text.trim().isEmpty ? null : _description.text.trim(),
      yearBuilt: int.parse(_year.text),
      length: double.parse(_length.text),
      capacity: int.parse(_capacity.text),
      cabins: int.parse(_cabins.text),
      bathrooms: _bathrooms.text.isEmpty ? null : int.tryParse(_bathrooms.text),
      pricePerDay: double.parse(_price.text),
      locationId: int.parse(_locationId.text),
      categoryId: int.parse(_categoryId.text),
      isActive: true,
    );

    try {
      if (widget.initial == null) {
        await widget.api.createYacht(detail);
      } else {
        await widget.api.updateYacht(detail);
      }
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${e.body}')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    prefixIcon: Icon(Icons.directions_boat_outlined),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<AppUser>(
                  value: _selectedOwner,
                  decoration: const InputDecoration(
                    labelText: 'Owner',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: widget.owners
                      .map(
                        (o) => DropdownMenuItem<AppUser>(
                          value: o,
                          child: Text('${o.displayName} (${o.username})'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedOwner = val;
                      _ownerId.text = val?.userId.toString() ?? '';
                    });
                  },
                  validator: (v) => v == null ? 'Select owner' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: int.tryParse(_year.text),
                        decoration: const InputDecoration(
                          labelText: 'Year',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                        ),
                        items: List<int>.generate(
                          40,
                          (i) => DateTime.now().year - i,
                        )
                            .map(
                              (y) => DropdownMenuItem<int>(
                                value: y,
                                child: Text(y.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          _year.text =
                              (val ?? DateTime.now().year).toString();
                        },
                        validator: (v) => v == null ? 'Year' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _length,
                        decoration: const InputDecoration(
                          labelText: 'Length (m)',
                          prefixIcon: Icon(Icons.straighten),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => double.tryParse(v ?? '') == null
                            ? 'Length'
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: int.tryParse(_capacity.text),
                        decoration: const InputDecoration(
                          labelText: 'Capacity',
                          prefixIcon: Icon(Icons.people_outline),
                        ),
                        items: List<int>.generate(20, (i) => i + 1)
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c,
                                child: Text(c.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          _capacity.text = (val ?? 1).toString();
                        },
                        validator: (v) => v == null ? 'Capacity' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: int.tryParse(_cabins.text),
                        decoration: const InputDecoration(
                          labelText: 'Cabins',
                          prefixIcon: Icon(Icons.king_bed_outlined),
                        ),
                        items: List<int>.generate(10, (i) => i + 1)
                            .map(
                              (c) => DropdownMenuItem<int>(
                                value: c,
                                child: Text(c.toString()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          _cabins.text = (val ?? 1).toString();
                        },
                        validator: (v) => v == null ? 'Cabins' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: _bathrooms.text.isEmpty
                            ? null
                            : int.tryParse(_bathrooms.text),
                        decoration: const InputDecoration(
                          labelText: 'Bathrooms',
                          prefixIcon: Icon(Icons.bathtub_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text('None'),
                          ),
                          ...List<int>.generate(8, (i) => i + 1).map(
                            (b) => DropdownMenuItem<int>(
                              value: b,
                              child: Text(b.toString()),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          _bathrooms.text = val?.toString() ?? '';
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _price,
                        decoration: const InputDecoration(
                          labelText: 'Price (€ / day)',
                          prefixIcon: Icon(Icons.euro_symbol),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) => double.tryParse(v ?? '') == null
                            ? 'Price'
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: int.tryParse(_locationId.text),
                  decoration: const InputDecoration(
                    labelText: 'Location',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  items: widget.cities
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.cityId,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    _locationId.text = (val ?? 0).toString();
                  },
                  validator: (v) => v == null ? 'Location' : null,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  value: int.tryParse(_categoryId.text),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: widget.categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.categoryId,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    _categoryId.text = (val ?? 0).toString();
                  },
                  validator: (v) => v == null ? 'Category' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    prefixIcon: Icon(Icons.notes_outlined),
                  ),
                  maxLines: 2,
                ),

                if (widget.initial?.yachtId != null) ...[
                  const SizedBox(height: 18),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.photo_library_outlined, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Images',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _imageUploading ? null : _pickAndUploadImage,
                        icon: _imageUploading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined, size: 18),
                        label: Text(_imageUploading ? 'Uploading...' : 'Add Image'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_imagesLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_images.isEmpty)
                    Container(
                      height: 80,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'No images yet. Click "Add Image" to upload.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    )
                  else
                    SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final img = _images[index];
                          return _buildImageTile(img);
                        },
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

String _formatEuroPrice(double value) {
  final intVal = value.round();
  final raw = intVal.toString();
  final buffer = StringBuffer();
  int count = 0;
  for (int i = raw.length - 1; i >= 0; i--) {
    buffer.write(raw[i]);
    count++;
    if (count == 3 && i != 0) {
      buffer.write('.');
      count = 0;
    }
  }
  final withDots = buffer.toString().split('').reversed.join();
  return '€$withDots';
}

Future<void> _showSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 360, vertical: 240),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF4CAF50),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
