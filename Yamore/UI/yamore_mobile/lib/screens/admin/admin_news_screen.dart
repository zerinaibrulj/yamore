import 'package:flutter/material.dart';
import '../../models/news_item.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

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

  bool _loading = true;
  String? _error;
  List<NewsItemModel> _items = const [];
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
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
      final paged = await _api.getNews(page: 0, pageSize: 100);
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
          await _showActionResultDialog(
            title: 'Published',
            message: 'The announcement was added successfully.',
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Text(
            'Create and manage news for the app. Each item shows the title, text, and time. On phones, the list is ordered with the newest first.',
            style: TextStyle(
              color: Color(0xFF424242),
              fontSize: 14,
              height: 1.35,
            ),
          ),
        ),
        Expanded(
          child: _items.isEmpty
              ? const Center(child: Text('No news items. Add the first one.'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
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
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _showAddDialog,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add news'),
            ),
          ),
        ),
      ],
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
