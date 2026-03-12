import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/service_model.dart';
import '../../models/service_category.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class OwnerServicesTab extends StatefulWidget {
  final AuthService authService;

  const OwnerServicesTab({super.key, required this.authService});

  @override
  State<OwnerServicesTab> createState() => _OwnerServicesTabState();
}

class _OwnerServicesTabState extends State<OwnerServicesTab> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  List<ServiceModel> _services = [];
  List<ServiceCategory> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getServices(pageSize: 100),
        _api.getServiceCategories(pageSize: 100),
      ]);
      if (mounted) {
        setState(() {
          _services = (results[0] as PagedServices).resultList;
          _categories = (results[1] as PagedServiceCategories).resultList;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load services: $e';
          _loading = false;
        });
      }
    }
  }

  String _categoryName(int? id) {
    if (id == null) return 'General';
    final match = _categories.where((c) => c.serviceCategoryId == id);
    return match.isNotEmpty ? match.first.name : 'Other';
  }

  Map<String, List<ServiceModel>> get _groupedServices {
    final map = <String, List<ServiceModel>>{};
    for (final s in _services) {
      final cat = _categoryName(s.serviceCategoryId);
      map.putIfAbsent(cat, () => []).add(s);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Icon(Icons.room_service_outlined, color: AppTheme.primaryBlue, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Additional Services',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: AppTheme.primaryBlue),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'To assign services to a specific yacht, go to Yachts → Edit → Services Offered.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
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
            FilledButton(onPressed: _loadAll, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.room_service_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No services available.', style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    final grouped = _groupedServices;
    final categoryNames = grouped.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      itemCount: categoryNames.length,
      itemBuilder: (context, index) {
        final catName = categoryNames[index];
        final services = grouped[catName]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      catName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${services.length} service${services.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            ...services.map((s) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
                  child: Icon(
                    _serviceIcon(catName),
                    color: AppTheme.primaryBlue,
                    size: 20,
                  ),
                ),
                title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                subtitle: s.description != null && s.description!.isNotEmpty
                    ? Text(s.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))
                    : null,
                trailing: s.price != null
                    ? Text(
                        '€${s.price!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1a237e),
                        ),
                      )
                    : null,
              ),
            )),
          ],
        );
      },
    );
  }

  IconData _serviceIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('water') || lower.contains('sport')) return Icons.pool;
    if (lower.contains('cater') || lower.contains('dining') || lower.contains('food')) return Icons.restaurant;
    if (lower.contains('crew') || lower.contains('staff') || lower.contains('skipper')) return Icons.groups;
    if (lower.contains('transport')) return Icons.local_taxi;
    if (lower.contains('excurs') || lower.contains('tour')) return Icons.explore;
    if (lower.contains('wellness') || lower.contains('spa')) return Icons.spa;
    if (lower.contains('entertain') || lower.contains('music')) return Icons.music_note;
    if (lower.contains('equip') || lower.contains('gear') || lower.contains('rental')) return Icons.surfing;
    if (lower.contains('event') || lower.contains('party')) return Icons.celebration;
    if (lower.contains('provision') || lower.contains('drink')) return Icons.local_bar;
    return Icons.miscellaneous_services;
  }
}
