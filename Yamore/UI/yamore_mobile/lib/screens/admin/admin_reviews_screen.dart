import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/review.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

class AdminReviewsScreen extends StatefulWidget {
  final AuthService authService;

  const AdminReviewsScreen({super.key, required this.authService});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  late final ApiService _api = ApiService(
    baseUrl: widget.authService.baseUrl,
    auth: widget.authService,
  );

  List<Review> _reviews = [];
  Map<int, String> _yachtNames = {};
  Map<int, String> _userNames = {};
  int? _totalCount;
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  final int _pageSize = 10;
  bool _filterReported = false;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _api.getReviews(
        page: _currentPage,
        pageSize: _pageSize,
        isReported: _filterReported ? true : null,
      );
      final reviews = result.resultList;
      final yachtIds = reviews.map((r) => r.yachtId).toSet().toList();
      final userIds = reviews.map((r) => r.userId).toSet().toList();
      final yachtFutures = yachtIds.map((id) async {
        try {
          final yacht = await _api.getYachtById(id);
          return MapEntry(id, yacht.name.isNotEmpty ? yacht.name : 'Unknown yacht');
        } catch (e) {
          debugPrint('Failed to load yacht $id for review list: $e');
          return MapEntry(id, 'Unknown yacht');
        }
      });
      final userFutures = userIds.map((id) async {
        try {
          final user = await _api.getUserById(id);
          final name = user.displayName;
          return MapEntry(id, name.isNotEmpty ? name : 'Guest user');
        } catch (e) {
          debugPrint('Failed to load user $id for review list: $e');
          return MapEntry(id, 'Guest user');
        }
      });
      final yachtResults = await Future.wait(yachtFutures);
      final userResults = await Future.wait(userFutures);
      final yachtNames = Map.fromEntries(yachtResults);
      final userNames = Map.fromEntries(userResults);
      if (mounted) {
        setState(() {
          _reviews = reviews;
          _yachtNames = yachtNames;
          _userNames = userNames;
          _totalCount = result.count;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load reviews: $e';
          _loading = false;
        });
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  Widget _buildStars(int? rating) {
    if (rating == null) return const Text('—');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: i < rating ? Colors.amber : Colors.grey.shade400,
        );
      }),
    );
  }

  Future<void> _deleteReview(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete review'),
        content: const Text(
          'Are you sure you want to delete this review? This action cannot be undone.',
        ),
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
        await _api.deleteReview(review.reviewId);
        await _loadReviews();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review deleted successfully.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete review: $e')),
          );
        }
      }
    }
  }

  Future<void> _respondToReview(Review review) async {
    final controller = TextEditingController(text: review.ownerResponse ?? '');
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Review'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (review.comment != null && review.comment!.isNotEmpty) ...[
                Text(
                  'User comment:',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review.comment!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Owner/Admin response',
                  hintText: 'Enter your response...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
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
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                await showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Invalid data'),
                    content: const Text(
                      'Please enter a response message before sending.',
                    ),
                    actions: [
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }
              if (context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Send Response'),
          ),
        ],
      ),
    );
    if (sent == true && controller.text.trim().isNotEmpty) {
      try {
        await _api.respondToReview(review.reviewId, controller.text.trim());
        await _loadReviews();
        if (mounted) {
          await _showSuccessDialog(
            title: 'Response sent',
            message: 'The response was sent successfully.',
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send response: $e')),
          );
        }
      }
    }
    controller.dispose();
  }

  Future<void> _viewReviewDetails(Review review) async {
    final yachtName = _yachtNames[review.yachtId] ?? 'Unknown yacht';
    final userName = _userNames[review.userId] ?? 'Guest user';
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.rate_review_outlined, size: 22),
            const SizedBox(width: 8),
            const Text('Review'),
            const Spacer(),
            if (review.isReported)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.flag, size: 14, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Text(
                      'Reported',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('User', userName),
              _detailRow('Yacht', yachtName),
              _detailRow('Rating', review.rating != null ? '${review.rating}/5' : '—'),
              _detailRow('Date', _formatDate(review.datePosted)),
              const Divider(height: 24),
              const Text('Comment:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review.comment ?? '(no comment)',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              if (review.ownerResponse != null && review.ownerResponse!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Owner response:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    review.ownerResponse!,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
                Text(
                  'Responded: ${_formatDate(review.ownerResponseDate)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (review.isReported)
            TextButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _api.unreportReview(review.reviewId);
                  if (mounted) {
                    await _loadReviews();
                    await _showSuccessDialog(
                      title: 'Marked as appropriate',
                      message:
                          'The review has been marked as appropriate successfully.',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('Mark as OK'),
            ),
          if (!review.isReported)
            TextButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await _api.reportReview(review.reviewId);
                  if (mounted) {
                    await _loadReviews();
                    await _showSuccessDialog(
                      title: 'Marked as inappropriate',
                      message:
                          'The review has been marked as inappropriate successfully.',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update status: $e')),
                    );
                  }
                }
              },
              icon: Icon(Icons.flag_outlined, size: 18, color: Colors.red.shade700),
              label: Text('Mark as inappropriate', style: TextStyle(color: Colors.red.shade700)),
            ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              const Icon(Icons.rate_review, color: AppTheme.primaryBlue),
              const SizedBox(width: 8),
              const Text(
                'Reviews',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              FilterChip(
                label: const Text('Reported only'),
                selected: _filterReported,
                onSelected: (val) {
                  setState(() {
                    _filterReported = val;
                    _currentPage = 0;
                  });
                  _loadReviews();
                },
                selectedColor: Colors.red.shade100,
                avatar: Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: _filterReported ? Colors.red : Colors.grey,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _loadReviews,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody()),
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
            FilledButton(onPressed: _loadReviews, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_reviews.isEmpty) {
      return const Center(child: Text('No reviews found.'));
    }

    final total = _totalCount ?? _reviews.length;
    final start = total == 0 ? 0 : _currentPage * _pageSize + 1;
    final end = (_currentPage * _pageSize + _reviews.length).clamp(0, total);
    final totalPages = total == 0 ? 1 : ((total + _pageSize - 1) / _pageSize).floor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  DataColumn(label: Text('Yacht')),
                  DataColumn(label: Text('User')),
                  DataColumn(label: Text('Rating')),
                  DataColumn(label: Text('Comment')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('')),
                ],
                rows: _reviews.asMap().entries.map((entry) {
                  final index = entry.key;
                  final r = entry.value;
                  final displayIndex = _currentPage * _pageSize + index + 1;
                  final commentPreview = (r.comment ?? '').length > 40
                      ? '${r.comment!.substring(0, 40)}...'
                      : (r.comment ?? '—');
                  return DataRow(
                    cells: [
                      DataCell(Text('$displayIndex.')),
                      DataCell(Text(_yachtNames[r.yachtId] ?? 'Unknown yacht')),
                      DataCell(Text(_userNames[r.userId] ?? 'Guest user')),
                      DataCell(_buildStars(r.rating)),
                      DataCell(
                        SizedBox(
                          width: 200,
                          child: Text(commentPreview, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      DataCell(Text(_formatDate(r.datePosted))),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (r.isReported)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Reported',
                                  style: TextStyle(fontSize: 11, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (r.ownerResponse != null && r.ownerResponse!.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Responded',
                                  style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                            if (!r.isReported && (r.ownerResponse == null || r.ownerResponse!.isEmpty))
                              const Text('OK', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      DataCell(
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined, size: 20),
                              tooltip: 'View details',
                              onPressed: () => _viewReviewDetails(r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.reply_outlined, size: 20),
                              tooltip: 'Respond',
                              onPressed: () => _respondToReview(r),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                              tooltip: 'Delete',
                              onPressed: () => _deleteReview(r),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPagination(start, end, total, totalPages),
      ],
    );
  }

  Widget _buildPagination(int start, int end, int total, int totalPages) {
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
                  'Page ${_currentPage + 1} of $totalPages',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ],
          ),
          Row(
            children: [
              Text('Rows per page: $_pageSize', style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              IconButton.filledTonal(
                style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () {
                        setState(() => _currentPage--);
                        _loadReviews();
                      }
                    : null,
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.chevron_right),
                onPressed: (_currentPage + 1) < totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _loadReviews();
                      }
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
