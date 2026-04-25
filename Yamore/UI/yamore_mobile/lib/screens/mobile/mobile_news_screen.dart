import 'package:flutter/material.dart';
import '../../models/news_item.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_pagination_bar.dart';

class MobileNewsScreen extends StatefulWidget {
  final AuthService authService;

  const MobileNewsScreen({super.key, required this.authService});

  @override
  State<MobileNewsScreen> createState() => _MobileNewsScreenState();
}

class _MobileNewsScreenState extends State<MobileNewsScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    auth: widget.authService,
  );

  static const int _pageSize = 10;

  int _currentPage = 0;
  int _totalCount = 0;

  bool _loading = true;
  String? _error;
  List<NewsItemModel> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _formatDate(DateTime? d) {
    final t = newsDisplayTime(d);
    if (t == null) return '';
    return '${t.day.toString().padLeft(2, '0')}.'
        '${t.month.toString().padLeft(2, '0')}.'
        '${t.year} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final paged = await _api.getNews(
        page: _currentPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      var total = paged.count ?? 0;
      if (paged.resultList.isEmpty && total > 0) {
        final maxPage = ((total - 1) / _pageSize).floor();
        if (_currentPage > maxPage) {
          setState(() {
            _currentPage = maxPage;
          });
          await _load();
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _items = paged.resultList;
        _totalCount = total;
        _loading = false;
        _error = null;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.displayMessage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News & notices'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading && _items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                  ),
                )
              : Column(
                  children: [
                    if (_loading) const LinearProgressIndicator(minHeight: 2),
                    Expanded(
                      child: _items.isEmpty
                          ? const Center(child: Text('No news yet.'))
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                itemCount: _items.length,
                                itemBuilder: (context, i) {
                                  final n = _items[i];
                                  return _NewsCard(
                                    item: n,
                                    dateLabel: _formatDate(n.createdAt),
                                  );
                                },
                              ),
                            ),
                    ),
                    if (_totalCount > 0)
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: AdminPaginationBar(
                            total: _totalCount,
                            currentPage: _currentPage,
                            pageSize: _pageSize,
                            itemsOnPage: _items.length,
                            loading: _loading,
                            narrowLayout: true,
                            onPrevious: () {
                              setState(() => _currentPage = _currentPage - 1);
                              _load();
                            },
                            onNext: () {
                              setState(() => _currentPage = _currentPage + 1);
                              _load();
                            },
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItemModel item;
  final String dateLabel;

  const _NewsCard({
    required this.item,
    required this.dateLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (dateLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              item.text,
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey.shade800,
                fontSize: 14,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
