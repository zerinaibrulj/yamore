import 'package:flutter/material.dart';
import '../../models/news_item.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/admin_pagination_bar.dart';

class AdminNewsScreen extends StatefulWidget {
  final AuthService authService;

  const AdminNewsScreen({super.key, required this.authService});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    username: widget.authService.username,
    password: widget.authService.password,
  );

  final _titleFilter = TextEditingController();
  final _textFilter = TextEditingController();

  static const int _pageSize = 10;

  int _currentPage = 0;
  int _totalCount = 0;

  bool _loading = true;
  String? _error;
  List<NewsItemModel> _items = const [];
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleFilter.dispose();
    _textFilter.dispose();
    super.dispose();
  }

  Future<void> _showActionResultDialog({
    required String title,
    required String message,
    IconData icon = Icons.check_circle_outline,
    Color? iconColor,
  }) async {
    if (!mounted) return;
    final color = iconColor ?? Colors.green;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 15,
                  height: 1.35,
                ),
              ),
            ],
          ),
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
        titleContains: _titleFilter.text.trim().isEmpty
            ? null
            : _titleFilter.text.trim(),
        textContains: _textFilter.text.trim().isEmpty
            ? null
            : _textFilter.text.trim(),
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

  Future<void> _showAddDialog() async {
    final titleC = TextEditingController();
    final textC = TextEditingController();
    if (!mounted) {
      titleC.dispose();
      textC.dispose();
      return;
    }
    final borderRadius = BorderRadius.circular(12);
    final fieldDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final canPublish = titleC.text.trim().isNotEmpty &&
              textC.text.trim().isNotEmpty;
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.newspaper_outlined,
                              color: AppTheme.primaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'New post',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fill in the title and the main text for the announcement.',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: titleC,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: fieldDecoration.copyWith(
                          labelText: 'Title *',
                          hintText: 'Short headline',
                        ),
                        maxLength: 200,
                        textInputAction: TextInputAction.next,
                        autofocus: true,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: textC,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: fieldDecoration.copyWith(
                          labelText: 'Text *',
                          alignLabelWithHint: true,
                          hintText: 'Full announcement for users…',
                        ),
                        minLines: 5,
                        maxLines: 10,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: canPublish
                                ? () => Navigator.of(ctx).pop(true)
                                : null,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            child: const Text('Publish'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    try {
      if (ok != true || !mounted) return;
      try {
        await _api.createNews(
          title: titleC.text.trim(),
          text: textC.text.trim(),
        );
        if (mounted) {
          setState(() => _currentPage = 0);
          await _showActionResultDialog(
            title: 'Published',
            message: 'The announcement was added successfully.',
          );
          if (mounted) await _load();
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.displayMessage)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e')),
          );
        }
      }
    } finally {
      titleC.dispose();
      textC.dispose();
    }
  }

  Future<void> _confirmDelete(NewsItemModel item) async {
    final y = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete post?'),
        content: Text('Remove "${item.title}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (y != true || !mounted) return;
    setState(() => _deletingId = item.newsId);
    try {
      await _api.deleteNews(item.newsId);
      if (mounted) {
        await _showActionResultDialog(
          title: 'Deleted',
          message: 'The announcement was removed successfully.',
        );
        await _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.displayMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  void _searchFromFirstPage() {
    setState(() {
      _currentPage = 0;
    });
    _load();
  }

  void _clearSearchAndReload() {
    _titleFilter.clear();
    _textFilter.clear();
    setState(() {
      _currentPage = 0;
    });
    _load();
  }


  Widget _buildTopHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(
              Icons.campaign_outlined,
              color: AppTheme.primaryBlue,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'News',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        FilledButton.icon(
          onPressed: _showAddDialog,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add news'),
          style: FilledButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && !_loading) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopHeader(context),
            const SizedBox(height: 8),
            const Text(
              'Create and manage platform announcements. Newest posts first (10 per page, same as other admin lists).',
              style: TextStyle(
                color: Color(0xFF424242),
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchCard(enabled: true),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade800),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTopHeader(context),
          const SizedBox(height: 8),
          const Text(
            'Create and manage platform announcements. Filter by title or text, then use Search. Newest posts first.',
            style: TextStyle(
              color: Color(0xFF424242),
              fontSize: 14,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          _buildSearchCard(enabled: !_loading),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _loading && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? Center(
                        child: Text(
                          _titleFilter.text.trim().isNotEmpty ||
                                  _textFilter.text.trim().isNotEmpty
                              ? 'No items match this search. Try different keywords or clear filters.'
                              : 'No news items yet. Use Add news above to publish the first announcement.',
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                          itemCount: _items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final n = _items[i];
                            final t = newsDisplayTime(n.createdAt);
                            return Card(
                              child: ListTile(
                                isThreeLine: n.text.length > 80,
                                title: Text(
                                  n.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${t != null ? _fmt(t) : '—'}\n${n.text}',
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(height: 1.2),
                                ),
                                trailing: _deletingId == n.newsId
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.red,
                                        ),
                                        onPressed: () => _confirmDelete(n),
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
          if (!_loading)
            AdminPaginationBar(
              total: _totalCount,
              currentPage: _currentPage,
              pageSize: _pageSize,
              itemsOnPage: _items.length,
              loading: _loading,
              onPrevious: () {
                setState(() => _currentPage--);
                _load();
              },
              onNext: () {
                setState(() => _currentPage++);
                _load();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSearchCard({required bool enabled}) {
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    );
    return Card(
      elevation: 0,
      color: const Color(0xFFF5F7FA),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                Icon(Icons.filter_alt_outlined, size: 20, color: Color(0xFF1976D2)),
                SizedBox(width: 8),
                Text(
                  'Search news',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 560;
                final titleField = TextField(
                  controller: _titleFilter,
                  enabled: enabled,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Title contains',
                    hintText: 'e.g. announcement',
                    border: fieldBorder,
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.title, size: 20),
                  ),
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _searchFromFirstPage(),
                );
                final textField = TextField(
                  controller: _textFilter,
                  enabled: enabled,
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: 'Text contains',
                    hintText: 'Search in body…',
                    border: fieldBorder,
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.notes, size: 20),
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchFromFirstPage(),
                );
                if (wide) {
                  return Row(
                    children: [
                      Expanded(child: titleField),
                      const SizedBox(width: 12),
                      Expanded(child: textField),
                    ],
                  );
                }
                return Column(
                  children: [
                    titleField,
                    const SizedBox(height: 10),
                    textField,
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: enabled ? _searchFromFirstPage : null,
                  icon: const Icon(Icons.search, size: 20),
                  label: const Text('Search'),
                ),
                OutlinedButton.icon(
                  onPressed: enabled ? _clearSearchAndReload : null,
                  icon: const Icon(Icons.clear, size: 20),
                  label: const Text('Clear filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime t) {
    return '${t.day.toString().padLeft(2, '0')}.'
        '${t.month.toString().padLeft(2, '0')}.'
        '${t.year} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }
}
