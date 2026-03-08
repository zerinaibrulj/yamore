import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/yacht_overview.dart';
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
                onPressed: _onAddYacht,
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
          ],
          rows: _yachts
              .map(
                (y) => DataRow(
                  cells: [
                    DataCell(Text(y.name)),
                    DataCell(Text(y.locationName ?? '—')),
                    DataCell(Text(y.ownerName ?? '—')),
                    DataCell(Text(y.yearBuilt?.toString() ?? '—')),
                    DataCell(Text(y.length != null ? '${y.length!.toStringAsFixed(2)} m' : '—')),
                    DataCell(Text('${y.capacity}')),
                    DataCell(Text('€${y.pricePerDay.toStringAsFixed(0)}')),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _onAddYacht() {
    // TODO: Open add yacht dialog or screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add Yacht – connect form to API')),
    );
  }
}
