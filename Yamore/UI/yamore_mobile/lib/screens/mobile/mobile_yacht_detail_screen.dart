import 'package:flutter/material.dart';

import '../../models/yacht_overview.dart';
import '../../models/yacht_detail.dart';
import '../../models/review.dart';
import '../../models/reservation.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

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
      setState(() {
        _detail = results[0] as YachtDetail;
        _reviews = pagedReviews.resultList;
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
                // Booking flow can be wired here.
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
                  overview.locationName!,
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
            if (count > 0)
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

