import 'package:flutter/material.dart';

import '../../models/yacht_overview.dart';
import '../../models/yacht_detail.dart';
import '../../models/review.dart';
import '../../models/reservation.dart';
import '../../models/user.dart';
import '../../models/yacht_image.dart';
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
  List<Reservation> _myReservationsForYacht = [];
  Review? _myReview;
  List<YachtImageModel> _yachtImages = [];
  Map<int, String> _reviewAuthorNames = {};
  bool _loading = true;
  bool _savingReview = false;
  String? _error;

  final PageController _imagePageController = PageController();
  int _imageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
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
        ),
        widget.api.getYachtImages(widget.overview.yachtId).catchError((_) => <YachtImageModel>[]),
      ]);
      if (!mounted) return;
      final pagedReviews = results[1] as PagedReviews;
      final pagedReservations = results[2] as PagedReservations;
      final allReviews = pagedReviews.resultList;
      final myReview = allReviews
          .where((r) => r.userId == widget.user.userId)
          .cast<Review?>()
          .firstWhere((_) => true, orElse: () => null);
      final images = results[3] as List<YachtImageModel>;
      final authorIds = allReviews.map((r) => r.userId).toSet().where((id) => id != widget.user.userId).toList();
      final names = <int, String>{};
      for (final id in authorIds) {
        try {
          final u = await widget.api.getUserById(id);
          if (u.displayName.isNotEmpty) names[id] = u.displayName;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _detail = results[0] as YachtDetail;
        _reviews = allReviews;
        _myReservationsForYacht = pagedReservations.resultList;
        _myReview = myReview;
        _yachtImages = images;
        _reviewAuthorNames = names;
        _imageIndex = 0;
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

  bool get _canReview => _myReservationsForYacht.isNotEmpty;

  Future<void> _openReviewSheet() async {
    if (!_canReview) return;
    final existing = _myReview;
    int tempRating = existing?.rating ?? 5;
    final commentCtrl =
        TextEditingController(text: existing?.comment ?? '');

    final result = await showModalBottomSheet<String>(
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
                      Text(
                        existing == null ? 'Your review' : 'Edit or delete your review',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(ctx).pop('cancel'),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      final selected = starValue <= tempRating;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () => setLocal(() => tempRating = starValue),
                          child: Icon(
                            selected ? Icons.star : Icons.star_border,
                            size: 40,
                            color: selected
                                ? const Color(0xFFFFC107)
                                : Colors.grey.shade400,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      '$tempRating of 5 stars',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                      onPressed: () => Navigator.of(ctx).pop('submit'),
                      child: Text(existing == null ? 'Submit review' : 'Save changes'),
                    ),
                  ),
                  if (existing != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: ctx,
                            builder: (c) => AlertDialog(
                              title: const Text('Delete review?'),
                              content: const Text(
                                'Your review will be permanently removed. This cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(c).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.of(c).pop(true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && ctx.mounted) {
                            try {
                              await widget.api.deleteReview(existing.reviewId);
                              if (!ctx.mounted) return;
                              setState(() {
                                _reviews = _reviews.where((r) => r.reviewId != existing.reviewId).toList();
                                _myReview = null;
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Review deleted.')),
                                );
                              }
                              Navigator.of(ctx).pop('delete');
                            } catch (e) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text('Failed to delete: $e')),
                                );
                              }
                            }
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        label: const Text(
                          'Delete my review',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == 'submit') {
      await _saveReview(tempRating, commentCtrl.text.trim());
    }
    commentCtrl.dispose();
  }

  Future<void> _saveReview(int rating, String? comment) async {
    if (!_canReview || rating <= 0) return;
    final reservationId =
        _myReview?.reservationId ?? _myReservationsForYacht.first.reservationId;
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
          // Images carousel
          _buildImageCarousel(),
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

  String _reviewAuthorName(Review r) {
    if (r.userId == widget.user.userId) return widget.user.displayName;
    return _reviewAuthorNames[r.userId] ?? 'Guest';
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
                _reviewAuthorName(r),
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

  Widget _buildImageCarousel() {
    final overview = widget.overview;

    // Deduplicate by yachtImageId (keep first occurrence), then sort by sortOrder
    final seenIds = <int>{};
    final images = _yachtImages
        .where((img) => seenIds.add(img.yachtImageId))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    // If no images from API, use thumbnail so we always show at least one
    final List<int> imageIds;
    if (images.isEmpty && overview.thumbnailImageId != null) {
      imageIds = [overview.thumbnailImageId!];
    } else if (images.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: _placeholderImage(),
      );
    } else {
      imageIds = images.map((e) => e.yachtImageId).toList();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            PageView.builder(
              controller: _imagePageController,
              itemCount: imageIds.length,
              onPageChanged: (i) => setState(() => _imageIndex = i),
              itemBuilder: (context, index) {
                final imageId = imageIds[index];
                return Image.network(
                  widget.api.yachtImageUrl(imageId),
                  key: ValueKey<int>(imageId),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  headers: widget.api.authHeaders,
                  errorBuilder: (_, __, ___) => _placeholderImage(),
                );
              },
            ),
            if (imageIds.length > 1)
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _CarouselArrow(
                    icon: Icons.chevron_left,
                    onTap: () {
                      final prev = _imageIndex - 1;
                      if (prev >= 0) {
                        _imagePageController.animateToPage(
                          prev,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            if (imageIds.length > 1)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _CarouselArrow(
                    icon: Icons.chevron_right,
                    onTap: () {
                      final next = _imageIndex + 1;
                      if (next < imageIds.length) {
                        _imagePageController.animateToPage(
                          next,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                  ),
                ),
              ),
            if (imageIds.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(imageIds.length, (i) {
                    final selected = i == _imageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: selected ? 10 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CarouselArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CarouselArrow({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black45,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

