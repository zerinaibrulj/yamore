import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/yacht_overview.dart';
import '../../models/yacht_detail.dart';
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
      final paged = await _api.getYachtOverviewForAdmin(page: 0, pageSize: 50);
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
          const SizedBox(height: 24),
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
                  onSelectChanged: (selected) {
                    if (selected == true) {
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

  Future<void> _openAddYachtDialog() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => YachtFormDialog(
        title: 'Add Yacht',
        api: _api,
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

  const YachtFormDialog({
    super.key,
    required this.title,
    required this.api,
    this.initial,
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
                TextFormField(
                  controller: _year,
                  decoration: const InputDecoration(labelText: 'Year built'),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Enter valid year' : null,
                ),
                TextFormField(
                  controller: _length,
                  decoration: const InputDecoration(labelText: 'Length (m)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid length' : null,
                ),
                TextFormField(
                  controller: _capacity,
                  decoration: const InputDecoration(labelText: 'Capacity (people)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Enter valid capacity' : null,
                ),
                TextFormField(
                  controller: _cabins,
                  decoration: const InputDecoration(labelText: 'Cabins'),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Enter valid cabins' : null,
                ),
                TextFormField(
                  controller: _bathrooms,
                  decoration: const InputDecoration(labelText: 'Bathrooms (optional)'),
                  keyboardType: TextInputType.number,
                ),
                TextFormField(
                  controller: _price,
                  decoration: const InputDecoration(labelText: 'Price per day (€)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid price' : null,
                ),
                TextFormField(
                  controller: _locationId,
                  decoration: const InputDecoration(labelText: 'Location ID (City)'),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Enter valid LocationId' : null,
                ),
                TextFormField(
                  controller: _categoryId,
                  decoration: const InputDecoration(labelText: 'Category ID'),
                  keyboardType: TextInputType.number,
                  validator: (v) => int.tryParse(v ?? '') == null ? 'Enter valid CategoryId' : null,
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
