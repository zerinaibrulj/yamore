import 'package:flutter/material.dart';
import '../../models/yacht_document.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/admin_pagination_bar.dart';

class AdminYachtDocumentsScreen extends StatefulWidget {
  final AuthService authService;

  const AdminYachtDocumentsScreen({super.key, required this.authService});

  @override
  State<AdminYachtDocumentsScreen> createState() =>
      _AdminYachtDocumentsScreenState();
}

class _AdminYachtDocumentsScreenState extends State<AdminYachtDocumentsScreen> {
  static const _pageSize = 10;

  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    auth: widget.authService,
  );

  List<YachtDocument> _pending = [];
  bool _loading = true;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<YachtDocument> get _sortedPending {
    final copy = List<YachtDocument>.from(_pending);
    copy.sort((a, b) {
      final byYacht = a.yachtId.compareTo(b.yachtId);
      if (byYacht != 0) return byYacht;
      return a.documentType.toLowerCase().compareTo(b.documentType.toLowerCase());
    });
    return copy;
  }

  int get _totalCount => _sortedPending.length;

  int get _totalPages {
    if (_totalCount == 0) return 1;
    return (_totalCount + _pageSize - 1) ~/ _pageSize;
  }

  int get _effectivePage => _currentPage.clamp(0, _totalPages - 1);

  List<YachtDocument> get _pageItems {
    final sorted = _sortedPending;
    if (sorted.isEmpty) return const [];
    final start = _effectivePage * _pageSize;
    if (start >= sorted.length) return const [];
    final end = (start + _pageSize).clamp(0, sorted.length);
    return sorted.sublist(start, end);
  }

  void _clampPage() {
    if (_totalCount == 0) {
      _currentPage = 0;
      return;
    }
    final maxPage = _totalPages - 1;
    if (_currentPage > maxPage) _currentPage = maxPage;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _api.getPendingYachtDocuments();
      if (!mounted) return;
      setState(() {
        _pending = list;
        _clampPage();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  String _yachtDisplayName(YachtDocument doc) {
    final name = doc.yachtName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Yacht #${doc.yachtId}';
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        content: Text(message),
      ),
    );
  }

  Future<void> _verify(YachtDocument doc, bool approve) async {
    String? reason;
    if (!approve) {
      final controller = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Rejection reason'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason (required)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Please enter a reason.')),
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Reject'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      reason = controller.text.trim();
      controller.dispose();
    }

    try {
      await _api.verifyYachtDocument(
        documentId: doc.yachtDocumentId,
        verificationStatus: approve ? 'Approved' : 'Rejected',
        rejectionReason: reason,
      );
      if (!mounted) return;
      _showSuccessSnackBar(
        approve
            ? 'Document approved successfully!'
            : 'Document rejected successfully.',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  List<Widget> _buildPageListItems() {
    final items = _pageItems;
    final widgets = <Widget>[];
    int? previousYachtId;

    for (final d in items) {
      if (previousYachtId != d.yachtId) {
        widgets.add(
          Padding(
            padding: EdgeInsets.only(
              top: previousYachtId == null ? 4 : 16,
              bottom: 10,
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sailing_outlined,
                    size: 22,
                    color: AppTheme.primaryBlue.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _yachtDisplayName(d),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: AppTheme.primaryBlue,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        previousYachtId = d.yachtId;
      }

      widgets.add(
        Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  YachtDocument.displayLabelForType(d.documentType),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (d.fileName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      d.fileName!,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Uploaded: ${YachtDocument.formatUploadedLocal(d.dateUploaded)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _verify(d, true),
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _verify(d, false),
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending yacht documents'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: _pending.isEmpty
                          ? const Center(
                              child: Text('No documents awaiting review.'),
                            )
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                                children: _buildPageListItems(),
                              ),
                            ),
                    ),
                    if (!_loading && _totalCount > 0)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: AdminPaginationBar(
                          total: _totalCount,
                          currentPage: _effectivePage,
                          pageSize: _pageSize,
                          itemsOnPage: _pageItems.length,
                          loading: _loading,
                          onPrevious: _effectivePage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                          onNext: (_effectivePage + 1) < _totalPages
                              ? () => setState(() => _currentPage++)
                              : null,
                        ),
                      ),
                  ],
                ),
    );
  }
}
