import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:brikle/ProfilePage/Model/review_model.dart';
import 'package:brikle/ProfilePage/View/reviewDialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewListScreen extends StatefulWidget {
  final int materialId;
  final String materialName;

  const ReviewListScreen({
    super.key,
    required this.materialId,
    required this.materialName,
  });

  @override
  State<ReviewListScreen> createState() => _ReviewListScreenState();
}

class _ReviewListScreenState extends State<ReviewListScreen> {
  late final ProfileController _ctrl = Get.find<ProfileController>();

  @override
  void initState() {
    super.initState();
    debugPrint('[ReviewListScreen] initState with materialId: ${widget.materialId}');
    _ctrl.fetchReviews(widget.materialId);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[ReviewListScreen] build()');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reviews & Ratings',
          style: GoogleFonts.manrope(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.inputText,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Get.back(),
          color: AppColors.inputText,
        ),
        actions: [
          IconButton(
            onPressed: () => _showReviewDialog(),
            icon: const Icon(Icons.rate_review_outlined),
            color: AppColors.primaryGreen,
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF3F4F6),
      body: Obx(() {
        if (_ctrl.isReviewsLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryGreen,
            ),
          );
        }

        if (_ctrl.reviews.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.star_border_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Reviews Yet',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inputText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Be the first to review this product!',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _showReviewDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    'Write a Review',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: () => _ctrl.fetchReviews(widget.materialId),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _ctrl.reviews.length,
            itemBuilder: (context, index) {
              final review = _ctrl.reviews[index];
              return _buildReviewCard(context, review);
            },
          ),
        );
      }),
    );
  }

  Widget _buildReviewCard(BuildContext context, ReviewModel review) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryGreen,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inputText,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: index < review.rating
                                ? Colors.amber
                                : Colors.grey.shade300,
                            size: 16,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          review.rating.toString(),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.textGray,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: GoogleFonts.manrope(
              fontSize: 14,
              color: AppColors.inputText,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateTime) {
    try {
      final parsed = DateTime.parse(dateTime);
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return dateTime;
    }
  }

  void _showReviewDialog() {
    Get.dialog(
      ReviewDialog(
        materialId: widget.materialId,
        materialName: widget.materialName,
      ),
      barrierDismissible: false,
    );
  }
}