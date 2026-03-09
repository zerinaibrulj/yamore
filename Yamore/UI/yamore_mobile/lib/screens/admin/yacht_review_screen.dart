import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/yacht_overview.dart';
import '../../models/yacht_detail.dart';
import '../../models/city.dart';
import '../../models/yacht_category.dart';
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

  // filters
  final TextEditingController _searchNameController = TextEditingController();
  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();
  int? _selectedSearchLocationId;

  // selection
  int? _selectedYachtId;

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
        page: 0,
        pageSize: 50,
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
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          showCheckboxColumn: true,
          headingRowColor: WidgetStateProperty.all(AppTheme.primaryBlue),
          headingTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          columns: const [
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
              .map(
                (y) => DataRow(
                  selected: _selectedYachtId == y.yachtId,
                  onSelectChanged: (selected) {
                    if (selected == true) {
                      setState(() {
                        _selectedYachtId = y.yachtId;
                      });
                      _openEditYachtDialog(y);
                    }
                  },
                  cells: [
                    DataCell(Text(y.name)),
                    DataCell(Text(y.locationName ?? '—')),
                    DataCell(Text(y.ownerName ?? '—')),
                    DataCell(Text(y.yearBuilt?.toString() ?? '—')),
                    DataCell(Text(y.length != null ? '${y.length!.toStringAsFixed(2)} m' : '—')),
                    DataCell(Text('${y.capacity}')),
                    DataCell(Text('€${y.pricePerDay.toStringAsFixed(0)}')),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        tooltip: 'Delete',
                        onPressed: () => _deleteYacht(y),
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
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
              onPressed: _loadYachts,
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
      ),
    );
    if (created == true) {
      await _loadYachts();
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
        ),
      );
      if (updated == true) {
        await _loadYachts();
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

  const YachtFormDialog({
    super.key,
    required this.title,
    required this.api,
    this.initial,
    required this.cities,
    required this.categories,
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
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                TextFormField(
                  controller: _ownerId,
                  decoration: const InputDecoration(labelText: 'Owner ID'),
                  keyboardType: TextInputType.number,
                ),
                DropdownButtonFormField<int>(
                  value: int.tryParse(_year.text),
                  decoration: const InputDecoration(labelText: 'Year built'),
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
                    _year.text = (val ?? DateTime.now().year).toString();
                  },
                  validator: (v) => v == null ? 'Select year' : null,
                ),
                TextFormField(
                  controller: _length,
                  decoration: const InputDecoration(labelText: 'Length (m)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid length' : null,
                ),
                DropdownButtonFormField<int>(
                  value: int.tryParse(_capacity.text),
                  decoration: const InputDecoration(labelText: 'Capacity (people)'),
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
                  validator: (v) => v == null ? 'Select capacity' : null,
                ),
                DropdownButtonFormField<int>(
                  value: int.tryParse(_cabins.text),
                  decoration: const InputDecoration(labelText: 'Cabins'),
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
                  validator: (v) => v == null ? 'Select cabins' : null,
                ),
                DropdownButtonFormField<int>(
                  value: _bathrooms.text.isEmpty ? null : int.tryParse(_bathrooms.text),
                  decoration: const InputDecoration(labelText: 'Bathrooms'),
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
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Price per day (€)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid price' : null,
                ),
                DropdownButtonFormField<int>(
                  value: int.tryParse(_locationId.text),
                  decoration: const InputDecoration(labelText: 'Location'),
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
                  validator: (v) => v == null ? 'Select location' : null,
                ),
                DropdownButtonFormField<int>(
                  value: int.tryParse(_categoryId.text),
                  decoration: const InputDecoration(labelText: 'Category'),
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
                  validator: (v) => v == null ? 'Select category' : null,
                ),
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(labelText: 'Description (optional)'),
                  maxLines: 2,
                ),
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
