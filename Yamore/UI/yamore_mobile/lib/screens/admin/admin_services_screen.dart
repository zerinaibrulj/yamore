import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/service_category.dart';
import '../../models/service_model.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class AdminServicesScreen extends StatefulWidget {
  final AuthService authService;

  const AdminServicesScreen({super.key, required this.authService});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen>
    with SingleTickerProviderStateMixin {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  late final TabController _tabController;

  // Categories state
  List<ServiceCategory> _categories = [];
  int? _catTotalCount;
  bool _catLoading = true;
  String? _catError;
  int _catPage = 0;
  final int _catPageSize = 10;

  // Services state
  List<ServiceModel> _services = [];
  int? _svcTotalCount;
  bool _svcLoading = true;
  String? _svcError;
  int _svcPage = 0;
  final int _svcPageSize = 10;

  // Cached categories for service dropdown
  List<ServiceCategory> _allCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCategories();
    _loadServices();
    _loadAllCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllCategories() async {
    try {
      final result = await _api.getServiceCategories(pageSize: 100);
      if (mounted) setState(() => _allCategories = result.resultList);
    } catch (_) {}
  }

  // ── Categories ──

  Future<void> _loadCategories() async {
    setState(() {
      _catLoading = true;
      _catError = null;
    });
    try {
      final result = await _api.getServiceCategories(
        page: _catPage,
        pageSize: _catPageSize,
      );
      if (mounted) {
        setState(() {
          _categories = result.resultList;
          _catTotalCount = result.count;
          _catLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _catError = 'Failed to load categories: $e';
          _catLoading = false;
        });
      }
    }
  }

  Future<void> _addCategory() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Category'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      try {
        await _api.insertServiceCategory(
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        );
        await _loadCategories();
        await _loadAllCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add category: $e')),
          );
        }
      }
    }
    nameCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _editCategory(ServiceCategory cat) async {
    final nameCtrl = TextEditingController(text: cat.name);
    final descCtrl = TextEditingController(text: cat.description ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Category'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved == true) {
      try {
        await _api.updateServiceCategory(
          cat.serviceCategoryId,
          name: nameCtrl.text.trim(),
          description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
        );
        await _loadCategories();
        await _loadAllCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update category: $e')),
          );
        }
      }
    }
    nameCtrl.dispose();
    descCtrl.dispose();
  }

  Future<void> _deleteCategory(ServiceCategory cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete category'),
        content: Text('Are you sure you want to delete "${cat.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteServiceCategory(cat.serviceCategoryId);
        await _loadCategories();
        await _loadAllCategories();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete category: $e')),
          );
        }
      }
    }
  }

  // ── Services ──

  Future<void> _loadServices() async {
    setState(() {
      _svcLoading = true;
      _svcError = null;
    });
    try {
      final result = await _api.getServices(
        page: _svcPage,
        pageSize: _svcPageSize,
      );
      if (mounted) {
        setState(() {
          _services = result.resultList;
          _svcTotalCount = result.count;
          _svcLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _svcError = 'Failed to load services: $e';
          _svcLoading = false;
        });
      }
    }
  }

  Future<void> _addService() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ServiceDialog(
        categories: _allCategories,
        onSave: (name, description, price, categoryId) async {
          await _api.insertService(
            name: name,
            description: description,
            price: price,
            serviceCategoryId: categoryId,
          );
        },
      ),
    );
    if (result == true) {
      await _loadServices();
    }
  }

  Future<void> _editService(ServiceModel svc) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _ServiceDialog(
        categories: _allCategories,
        existing: svc,
        onSave: (name, description, price, categoryId) async {
          await _api.updateService(
            svc.serviceId,
            name: name,
            description: description,
            price: price,
            serviceCategoryId: categoryId,
          );
        },
      ),
    );
    if (result == true) {
      await _loadServices();
    }
  }

  Future<void> _deleteService(ServiceModel svc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete service'),
        content: Text('Are you sure you want to delete "${svc.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await _api.deleteService(svc.serviceId);
        await _loadServices();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete service: $e')),
          );
        }
      }
    }
  }

  String _categoryName(int? id) {
    if (id == null) return '—';
    final match = _allCategories.where((c) => c.serviceCategoryId == id);
    return match.isNotEmpty ? match.first.name : 'ID: $id';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.room_service_outlined, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              const Text(
                'Services',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  _loadCategories();
                  _loadServices();
                  _loadAllCategories();
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Categories'),
              Tab(text: 'Services'),
            ],
            labelColor: AppTheme.primaryBlue,
            indicatorColor: AppTheme.primaryBlue,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCategoriesTab(),
                _buildServicesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Categories Tab ──

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const Spacer(),
            FilledButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Category'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildCategoryBody()),
      ],
    );
  }

  Widget _buildCategoryBody() {
    if (_catLoading) return const Center(child: CircularProgressIndicator());
    if (_catError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_catError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadCategories, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_categories.isEmpty) return const Center(child: Text('No categories found.'));

    final total = _catTotalCount ?? _categories.length;
    final start = total == 0 ? 0 : _catPage * _catPageSize + 1;
    final end = (_catPage * _catPageSize + _categories.length).clamp(0, total);
    final totalPages = total == 0 ? 1 : ((total + _catPageSize - 1) / _catPageSize).floor();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: DataTable(
              showCheckboxColumn: false,
              headingRowColor: WidgetStateProperty.all(AppTheme.primaryBlue),
              headingTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              columns: const [
                DataColumn(label: Text('No.')),
                DataColumn(label: Text('Name')),
                DataColumn(label: Text('Description')),
                DataColumn(label: Text('')),
              ],
              rows: _categories.asMap().entries.map((entry) {
                final index = entry.key;
                final c = entry.value;
                return DataRow(cells: [
                  DataCell(Text('${_catPage * _catPageSize + index + 1}.')),
                  DataCell(Text(c.name)),
                  DataCell(SizedBox(
                    width: 300,
                    child: Text(c.description ?? '—', overflow: TextOverflow.ellipsis),
                  )),
                  DataCell(Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        tooltip: 'Edit',
                        onPressed: () => _editCategory(c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                        tooltip: 'Delete',
                        onPressed: () => _deleteCategory(c),
                      ),
                    ],
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPagination(
          start, end, total, totalPages,
          page: _catPage,
          pageSize: _catPageSize,
          onPrev: () {
            setState(() => _catPage--);
            _loadCategories();
          },
          onNext: () {
            setState(() => _catPage++);
            _loadCategories();
          },
        ),
      ],
    );
  }

  // ── Services Tab ──

  Widget _buildServicesTab() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            const Spacer(),
            FilledButton.icon(
              onPressed: _addService,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Service'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(child: _buildServiceBody()),
      ],
    );
  }

  Widget _buildServiceBody() {
    if (_svcLoading) return const Center(child: CircularProgressIndicator());
    if (_svcError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_svcError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(onPressed: _loadServices, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_services.isEmpty) return const Center(child: Text('No services found.'));

    final total = _svcTotalCount ?? _services.length;
    final start = total == 0 ? 0 : _svcPage * _svcPageSize + 1;
    final end = (_svcPage * _svcPageSize + _services.length).clamp(0, total);
    final totalPages = total == 0 ? 1 : ((total + _svcPageSize - 1) / _svcPageSize).floor();

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.all(AppTheme.primaryBlue),
                headingTextStyle: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                columns: const [
                  DataColumn(label: Text('No.')),
                  DataColumn(label: Text('Name')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('')),
                ],
                rows: _services.asMap().entries.map((entry) {
                  final index = entry.key;
                  final s = entry.value;
                  return DataRow(cells: [
                    DataCell(Text('${_svcPage * _svcPageSize + index + 1}.')),
                    DataCell(Text(s.name)),
                    DataCell(SizedBox(
                      width: 200,
                      child: Text(s.description ?? '—', overflow: TextOverflow.ellipsis),
                    )),
                    DataCell(Text(s.price != null ? '€${s.price!.toStringAsFixed(2)}' : '—')),
                    DataCell(Text(_categoryName(s.serviceCategoryId))),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          tooltip: 'Edit',
                          onPressed: () => _editService(s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          tooltip: 'Delete',
                          onPressed: () => _deleteService(s),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPagination(
          start, end, total, totalPages,
          page: _svcPage,
          pageSize: _svcPageSize,
          onPrev: () {
            setState(() => _svcPage--);
            _loadServices();
          },
          onNext: () {
            setState(() => _svcPage++);
            _loadServices();
          },
        ),
      ],
    );
  }

  Widget _buildPagination(
    int start,
    int end,
    int total,
    int totalPages, {
    required int page,
    required int pageSize,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    return Container(
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
                total == 0 ? 'No records' : 'Showing $start–$end of $total',
                style: const TextStyle(fontSize: 12),
              ),
              if (total > 0) ...[
                const SizedBox(width: 8),
                Text(
                  'Page ${page + 1} of $totalPages',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
          Row(
            children: [
              Text('Rows per page: $pageSize', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.chevron_left),
                onPressed: page > 0 ? onPrev : null,
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.chevron_right),
                onPressed: (page + 1) < totalPages ? onNext : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceDialog extends StatefulWidget {
  final List<ServiceCategory> categories;
  final ServiceModel? existing;
  final Future<void> Function(String name, String? description, double? price, int? categoryId) onSave;

  const _ServiceDialog({
    required this.categories,
    this.existing,
    required this.onSave,
  });

  @override
  State<_ServiceDialog> createState() => _ServiceDialogState();
}

class _ServiceDialogState extends State<_ServiceDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  int? _selectedCategoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.existing?.price?.toStringAsFixed(2) ?? '',
    );
    _selectedCategoryId = widget.existing?.serviceCategoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        _nameCtrl.text.trim(),
        _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        _priceCtrl.text.trim().isEmpty ? null : double.tryParse(_priceCtrl.text.trim()),
        _selectedCategoryId,
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Service' : 'Edit Service'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price (€)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: _selectedCategoryId,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('None'),
                ),
                ...widget.categories.map(
                  (c) => DropdownMenuItem<int?>(
                    value: c.serviceCategoryId,
                    child: Text(c.name),
                  ),
                ),
              ],
              onChanged: (val) => setState(() => _selectedCategoryId = val),
            ),
          ],
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
