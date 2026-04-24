import 'package:flutter/material.dart';
import '../../models/news_item.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class MobileNewsScreen extends StatefulWidget {
  final AuthService authService;

  const MobileNewsScreen({super.key, required this.authService});

  @override
  State<MobileNewsScreen> createState() => _MobileNewsScreenState();
}

class _MobileNewsScreenState extends State<MobileNewsScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  bool _loading = true;
  String? _error;
  List<NewsItemModel> _items = const [];
  static const int _pageSize = 50;

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
      final paged = await _api.getNews(page: 0, pageSize: _pageSize);
      if (!mounted) return;
      setState(() {
        _items = paged.resultList;
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
          ),
        ],
      ),
      body: _loading
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
              : _items.isEmpty
                  ? const Center(child: Text('No news yet.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final n = _items[i];
                          return _NewsCard(
                            item: n,
                            dateLabel: _formatDate(n.createdAt),
                            onTap: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                showDragHandle: true,
                                builder: (ctx) {
                                  return DraggableScrollableSheet(
                                    initialChildSize: 0.65,
                                    minChildSize: 0.4,
                                    maxChildSize: 0.95,
                                    expand: false,
                                    builder: (context, scroll) {
                                      return SingleChildScrollView(
                                        controller: scroll,
                                        padding: const EdgeInsets.all(20),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              n.title,
                                              style: const TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            if (n.createdAt != null) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                _formatDate(n.createdAt),
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 12),
                                            Text(
                                              n.text,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                height: 1.45,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItemModel item;
  final String dateLabel;
  final VoidCallback onTap;

  const _NewsCard({
    required this.item,
    required this.dateLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
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
                maxLines: 3,
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
      ),
    );
  }
}
