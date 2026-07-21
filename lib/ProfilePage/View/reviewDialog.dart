import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ReviewDialog extends StatefulWidget {
  final int materialId;
  final String materialName;

  const ReviewDialog({
    super.key,
    required this.materialId,
    required this.materialName,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  final ProfileController _ctrl = Get.find<ProfileController>();
  bool _isSubmitted = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isSubmitted ? 'Thank You!' : 'Rate this Product',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inputText,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Get.back(),
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: AppColors.textGray,
                ),
              ],
            ),

            if (_isSubmitted) ...[
              const SizedBox(height: 16),
              Icon(
                Icons.check_circle_outline,
                size: 64,
                color: AppColors.primaryGreen,
              ),
              const SizedBox(height: 12),
              Text(
                'Your review has been submitted!',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inputText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Thank you for your feedback.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  onPressed: () => Get.back(),
                  child: Text(
                    'Done',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                widget.materialName,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.textGray,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Star Rating - Flipkart style
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final int starNumber = index + 1;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = starNumber;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        starNumber <= _selectedRating
                            ? Icons.star
                            : Icons.star_border,
                        color: starNumber <= _selectedRating
                            ? Colors.amber
                            : Colors.grey.shade300,
                        size: 36,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedRating > 0
                    ? _getRatingLabel(_selectedRating)
                    : 'Tap to rate',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _selectedRating > 0
                      ? Colors.amber
                      : AppColors.textGray,
                ),
              ),
              const SizedBox(height: 20),

              // Comment field
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 500,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  color: AppColors.inputText,
                ),
                decoration: InputDecoration(
                  hintText: 'Share your experience with this product...',
                  hintStyle: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textGray,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryGreen),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),

              // Submit button
              Obx(() {
                final bool isLoading = _ctrl.isReviewSubmitting.value;
                return SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedRating > 0
                          ? AppColors.primaryGreen
                          : Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: (_selectedRating == 0 || isLoading)
                        ? null
                        : _submitReview,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Submit Review',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _selectedRating > 0
                                  ? Colors.white
                                  : AppColors.textGray,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent!';
      default:
        return '';
    }
  }

  void _submitReview() async {
    if (_selectedRating == 0) return;

    final success = await _ctrl.submitReview(
      materialId: widget.materialId,
      rating: _selectedRating,
      comment: _commentController.text.trim(),
    );

    if (success) {
      setState(() {
        _isSubmitted = true;
      });
    }
  }
}
