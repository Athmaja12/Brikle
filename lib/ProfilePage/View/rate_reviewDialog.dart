// import 'package:flutter/material.dart';
// import 'package:brikle/ApiConfiguration/apiservice.dart';
// import 'package:brikle/ProfilePage/Model/review_model.dart';

// /// Call this from Order List OR Order Details — same dialog either way.
// /// Returns the submitted ReviewModel on success, null if cancelled.
// ///
// /// Usage:
// ///   final review = await showRateReviewDialog(
// ///     context: context,
// ///     materialId: order.materialId,
// ///   );
// ///   if (review != null) {
// ///     setState(() => order.review = review);
// ///   }
// Future<ReviewModel?> showRateReviewDialog({
//   required BuildContext context,
//   required int materialId,
// }) {
//   int selectedRating = 0;
//   final commentController = TextEditingController();
//   bool isSubmitting = false;

//   return showDialog<ReviewModel>(
//     context: context,
//     barrierDismissible: true,
//     builder: (dialogContext) {
//       return StatefulBuilder(
//         builder: (context, setState) {
//           return AlertDialog(
//             title: const Text('Rate & Review'),
//             content: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: CrossAxisAlignment.stretch,
//                 children: [
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: List.generate(5, (index) {
//                       final starValue = index + 1;
//                       return IconButton(
//                         iconSize: 32,
//                         icon: Icon(
//                           starValue <= selectedRating
//                               ? Icons.star
//                               : Icons.star_border,
//                           color: Colors.amber,
//                         ),
//                         onPressed: isSubmitting
//                             ? null
//                             : () => setState(() => selectedRating = starValue),
//                       );
//                     }),
//                   ),
//                   const SizedBox(height: 12),
//                   TextField(
//                     controller: commentController,
//                     maxLines: 4,
//                     enabled: !isSubmitting,
//                     decoration: const InputDecoration(
//                       hintText: 'Share your experience (optional)',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: isSubmitting
//                     ? null
//                     : () => Navigator.pop(dialogContext),
//                 child: const Text('Cancel'),
//               ),
//               ElevatedButton(
//                 onPressed: (selectedRating == 0 || isSubmitting)
//                     ? null
//                     : () async {
//                         setState(() => isSubmitting = true);
//                         try {
//                           final response = await ApiService.postMaterialReview(
//                             materialId: materialId,
//                             rating: selectedRating,
//                             comment: commentController.text.trim(),
//                           );
//                           if (response.success && response.review != null) {
//                             Navigator.pop(dialogContext, response.review);
//                           } else {
//                             setState(() => isSubmitting = false);
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text(response.message)),
//                             );
//                           }
//                         } catch (e) {
//                           setState(() => isSubmitting = false);
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text('Something went wrong. Try again.'),
//                             ),
//                           );
//                         }
//                       },
//                 child: isSubmitting
//                     ? const SizedBox(
//                         height: 16,
//                         width: 16,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       )
//                     : const Text('Submit'),
//               ),
//             ],
//           );
//         },
//       );
//     },
//   );
// }