import 'package:flutter/material.dart';

import '../../models/yacht_overview.dart';
import '../../models/yacht_detail.dart';
import '../../models/review.dart';
import '../../models/reservation.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'mobile_booking_calendar_screen.dart';

class MobileYachtDetailScreen extends StatefulWidget {
  final ApiService api;
  final AppUser user;
  final YachtOverview overview;

  const MobileYachtDetailScreen({
    super.key,
    required this.api,
    required this.user,
    required this.overview,
  });

  @override
  State<MobileYachtDetailScreen> createState() =>
      _MobileYachtDetailScreenState();
}

class _MobileYachtDetailScreenState extends State<MobileYachtDetailScreen> {
  YachtDetail? _detail;
  List<Review> _reviews = [];
  List<Reservation> _completedReservations = [];
  Review? _myReview;
  bool _loading = true;
  bool _savingReview = false;
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
        widget.api.getYachtById(widget.overview.yachtId),
        widget.api.getReviews(
          page: 0,
          pageSize: 20,
          yachtId: widget.overview.yachtId,
        ),
        widget.api.getReservations(
          page: 0,
          pageSize: 50,
          userId: widget.user.userId,
          yachtId: widget.overview.yachtId,
          status: 'Completed',
        ),
      ]);
      if (!mounted) return;
      final pagedReviews = results[1] as PagedReviews;
      final pagedReservations = results[2] as PagedReservations;
      final allReviews = pagedReviews.resultList;
      final myReview = allReviews
          .where((r) => r.userId == widget.user.userId)
          .cast<Review?>()
          .firstWhere((_) => true, orElse: () => null);
      setState(() {
        _detail = results[0] as YachtDetail;
        _reviews = allReviews;
        _completedReservations = pagedReservations.resultList;
        _myReview = myReview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load yacht details: $e';
        _loading = false;
      });
    }
  }

  double? get _averageRating {
    final rated =
        _reviews.where((r) => r.rating != null && r.rating! > 0).toList();
    if (rated.isEmpty) return null;
    final sum = rated.fold<int>(0, (acc, r) => acc + r.rating!);
    return sum / rated.length;
  }

  int get _reviewCount =>
      _reviews.where((r) => r.rating != null && r.rating! > 0).length;

  bool get _canReview => _completedReservations.isNotEmpty;

  Future<void> _openReviewSheet() async {
    if (!_canReview) return;
    final existing = _myReview;
    int tempRating = existing?.rating ?? 5;
    final commentCtrl =
        TextEditingController(text: existing?.comment ?? '');

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: StatefulBuilder(
              builder: (ctx, setLocal) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Your review',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'How was your experience with this yacht?',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final filled = starValue <= tempRating;
                      return IconButton(
                        onPressed: () =>
                            setLocal(() => tempRating = starValue),
                        icon: Icon(
                          filled ? Icons.star : Icons.star_border,
                          color: const Color(0xFFFFC107),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Comment (optional)',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Submit review'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _saveReview(tempRating, commentCtrl.text.trim());
    }
    commentCtrl.dispose();
  }

  Future<void> _saveReview(int rating, String? comment) async {
    if (!_canReview || rating <= 0) return;
    final reservationId =
        _myReview?.reservationId ?? _completedReservations.first.reservationId;
    setState(() => _savingReview = true);
    try {
      Review updated;
      if (_myReview == null) {
        updated = await widget.api.createReview(
          reservationId: reservationId,
          userId: widget.user.userId,
          yachtId: widget.overview.yachtId,
          rating: rating,
          comment: comment?.isEmpty == true ? null : comment,
        );
        _reviews = [..._reviews, updated];
      } else {
        updated = await widget.api.updateReview(
          reviewId: _myReview!.reviewId,
          reservationId: reservationId,
          userId: widget.user.userId,
          yachtId: widget.overview.yachtId,
          rating: rating,
          comment: comment?.isEmpty == true ? null : comment,
        );
        _reviews = _reviews
            .map((r) => r.reviewId == updated.reviewId ? updated : r)
            .toList();
      }
      setState(() {
        _myReview = updated;
        _savingReview = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review saved.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingReview = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save review: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = widget.overview;
    return Scaffold(
      appBar: AppBar(
        title: Text(overview.name),
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
                      Text(
                        _error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadAll,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ))
              : _buildContent(),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SizedBox(
            height: 48,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MobileBookingCalendarScreen(
                      api: widget.api,
                      user: widget.user,
                      overview: widget.overview,
                    ),
                  ),
                );
              },
              child: const Text(
                'Book Now',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final overview = widget.overview;
    final avg = _averageRating ?? overview.averageRating;
    final count = _reviewCount > 0 ? _reviewCount : overview.reviewCount;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: overview.thumbnailImageId != null
                ? Image.network(
                    widget.api.yachtImageUrl(overview.thumbnailImageId!),
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    headers: widget.api.authHeaders,
                  )
                : _placeholderImage(),
          ),
          const SizedBox(height: 12),
          // Title + rating row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  overview.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (avg != null && count > 0)
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 20, color: Color(0xFFFFC107)),
                    const SizedBox(width: 4),
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '($count)',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade700),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (overview.locationName != null)
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  overview.countryName != null
                      ? '${overview.locationName!}, ${overview.countryName!}'
                      : overview.locationName!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          _buildSpecsRow(),
          const SizedBox(height: 16),
          _buildPriceSection(),
          _buildDescriptionSection(),
          const SizedBox(height: 24),
          _buildReviewsSection(avg, count),
        ],
      ),
    );
  }

  Widget _buildSpecsRow() {
    final d = _detail;
    final overview = widget.overview;
    final lengthFeet = overview.length != null ? overview.length! * 3.28084 : null;
    return Row(
      children: [
        if (overview.yearBuilt != null) ...[
          _infoChip(Icons.calendar_today_outlined, '${overview.yearBuilt}'),
          const SizedBox(width: 8),
        ],
        _infoChip(Icons.king_bed_outlined,
            d?.cabins != null ? '${d!.cabins} cabins' : 'Cabins'),
        const SizedBox(width: 8),
        _infoChip(Icons.bathtub_outlined,
            d?.bathrooms != null ? '${d!.bathrooms} baths' : 'Bathrooms'),
        const SizedBox(width: 8),
        _infoChip(Icons.people_outline, '${overview.capacity} guests'),
        const SizedBox(width: 8),
        if (lengthFeet != null)
          _infoChip(
            Icons.straighten,
            '${lengthFeet.toStringAsFixed(0)} ft',
          ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    final desc = _detail?.description;
    if (desc == null || desc.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'About this yacht',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
        ),
      ],
    );
  }

  Widget _buildPriceSection() {
    final overview = widget.overview;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total price',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'US \$${overview.pricePerDay.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(double? avg, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Yacht reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            if (_canReview)
              TextButton(
                onPressed: _openReviewSheet,
                child: Text(
                  _myReview == null ? 'Write a review' : 'Edit your review',
                  style: const TextStyle(fontSize: 13),
                ),
              )
            else if (count > 0)
              Text(
                '$count review${count == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (avg != null && count > 0)
          Row(
            children: [
              const Icon(Icons.star, color: Color(0xFFFFC107)),
              const SizedBox(width: 4),
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(width: 6),
              Text(
                'out of 5',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          )
        else
          Text(
            'No reviews yet. Be the first to share your experience.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        const SizedBox(height: 12),
        ..._reviews.take(3).map(_buildReviewCard),
      ],
    );
  }

  Widget _buildReviewCard(Review r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Guest #${r.userId}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (r.rating != null)
                Row(
                  children: [
                    const Icon(Icons.star,
                        size: 16, color: Color(0xFFFFC107)),
                    const SizedBox(width: 2),
                    Text(
                      '${r.rating}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
            ],
          ),
          if (r.comment != null && r.comment!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.comment!,
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlue),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sailing, size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 4),
          Text(
            'No image',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

