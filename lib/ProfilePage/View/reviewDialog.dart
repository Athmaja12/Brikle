// // lib/ProfilePage/View/reviewDialog.dart

// import 'package:brikle/AppStyle/appcolors.dart';
// import 'package:brikle/ProfilePage/Controller/profile_provider.dart';
// import 'package:brikle/ProfilePage/Model/review_model.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';

// /// Simple star + text review dialog. Nothing else — no title field, no
// /// photo upload, no "recommend this product" toggle. Matches the API
// /// exactly: POST { rating, comment } → { id, user_name, rating, comment,
// /// created_at }.
// class ReviewDialog extends StatefulWidget {
//   final int materialId;
//   final String materialName;

//   /// NEW — optional. When this dialog is opened from a specific order
//   /// (Order Details / Order List), pass that order's id here so
//   /// ProfileController.submitReview can stamp the created review onto the
//   /// matching OrderModel directly. Leave null when there's no specific
//   /// order in context (e.g. opened from the material's Review List
//   /// screen).
//   final int? orderId;

//   const ReviewDialog({
//     super.key,
//     required this.materialId,
//     required this.materialName,
//     this.orderId,
//   });

//   @override
//   State<ReviewDialog> createState() => _ReviewDialogState();
// }

// class _ReviewDialogState extends State<ReviewDialog> {
//   int _rating = 0;
//   final TextEditingController _commentController = TextEditingController();
//   late final ProfileController _controller = Get.find<ProfileController>();

//   @override
//   void dispose() {
//     _commentController.dispose();
//     super.dispose();
//   }

//   Future<void> _submit() async {
//     if (_rating == 0) {
//       Get.snackbar(
//         'Select a rating',
//         'Please tap a star to rate this product before submitting.',
//         backgroundColor: AppColors.errorRed,
//         colorText: Colors.white,
//         snackPosition: SnackPosition.BOTTOM,
//       );
//       return;
//     }

//     // FIX: submitReview now returns the created ReviewModel (or null on
//     // failure) instead of a bare bool, so the caller (whoever opened this
//     // dialog) can actually read what was submitted.
//     final createdReview = await _controller.submitReview(
//       materialId: widget.materialId,
//       rating: _rating,
//       comment: _commentController.text.trim(),
//       orderId: widget.orderId,
//     );

//     if (createdReview != null && mounted) {
//       // FIX: was bare Get.back() — the caller got no result and had no way
//       // to know a review was created, so "already reviewed" / updated
//       // states never appeared anywhere after a successful submit.
//       Get.back(result: createdReview);
//     }
//     // On failure, ProfileController.submitReview already shows a snackbar
//     // via _showStatusSnackbar — dialog stays open so the user can retry.
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Obx(() {
//           final isSubmitting = _controller.isReviewSubmitting.value;

//           return Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Row(
//                 children: [
//                   Expanded(
//                     child: Text(
//                       'Rate & Review',
//                       style: GoogleFonts.manrope(
//                         fontSize: 18,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.inputText,
//                       ),
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: isSubmitting ? null : () => Get.back(),
//                     child: const Icon(Icons.close, size: 20),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 4),
//               Text(
//                 widget.materialName,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//                 style: GoogleFonts.manrope(
//                   fontSize: 13,
//                   color: AppColors.textGray,
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // ── Stars — tap any star to set the rating ──────────────
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: List.generate(5, (index) {
//                   final starValue = index + 1;
//                   final filled = starValue <= _rating;
//                   return GestureDetector(
//                     onTap: isSubmitting
//                         ? null
//                         : () => setState(() => _rating = starValue),
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 4),
//                       child: Icon(
//                         filled ? Icons.star_rounded : Icons.star_border_rounded,
//                         size: 38,
//                         color: filled
//                             ? const Color(0xFFFFB800)
//                             : Colors.grey.shade300,
//                       ),
//                     ),
//                   );
//                 }),
//               ),
//               const SizedBox(height: 20),

//               // ── Comment ──────────────────────────────────────────────
//               TextField(
//                 controller: _commentController,
//                 enabled: !isSubmitting,
//                 maxLines: 4,
//                 maxLength: 500,
//                 style: GoogleFonts.manrope(fontSize: 14),
//                 decoration: InputDecoration(
//                   hintText: 'Share your experience with this product...',
//                   hintStyle: GoogleFonts.manrope(
//                     fontSize: 13,
//                     color: AppColors.textGray,
//                   ),
//                   filled: true,
//                   fillColor: const Color(0xFFFAFAFA),
//                   contentPadding: const EdgeInsets.all(14),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: AppColors.inputBorder),
//                   ),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: AppColors.inputBorder),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(
//                       color: AppColors.primaryGreen,
//                       width: 1.5,
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: isSubmitting ? null : _submit,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primaryGreen,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: isSubmitting
//                       ? const SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: Colors.white,
//                           ),
//                         )
//                       : Text(
//                           'Submit Review',
//                           style: GoogleFonts.manrope(
//                             fontSize: 15,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           );
//         }),
//       ),
//     );
//   }
// }