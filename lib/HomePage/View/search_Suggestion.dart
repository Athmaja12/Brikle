// import 'package:brikle/AppStyle/appcolors.dart';
// import 'package:brikle/AppStyle/appstyle.dart';
// import 'package:brikle/HomePage/Controller/search_provider.dart'; // Updated import
// import 'package:brikle/HomePage/Model/search_model.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// bool _isValidImageUrl(String? url) {
//   if (url == null) return false;
//   final trimmed = url.trim();
//   if (trimmed.isEmpty) return false;
//   final uri = Uri.tryParse(trimmed);
//   if (uri == null) return false;
//   if (!(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) return false;
//   if (uri.host.isEmpty) return false;
//   return true;
// }

// class SearchSuggestions extends StatelessWidget {
//   const SearchSuggestions({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final searchController = Get.find<AppSearchController>(); // Updated type

//     return Obx(() {
//       // Only show if search is active and has query
//       if (!searchController.isFocused.value ||
//           searchController.searchQuery.isEmpty) {
//         return const SizedBox.shrink();
//       }

//       // Show loading state
//       if (searchController.isLoading.value) {
//         return Container(
//           padding: const EdgeInsets.all(20),
//           child: const Center(
//             child: SizedBox(
//               height: 24,
//               width: 24,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           ),
//         );
//       }

//       // Show no results
//       if (searchController.searchResults.isEmpty &&
//           searchController.searchQuery.isNotEmpty) {
//         return Container(
//           padding: const EdgeInsets.all(20),
//           child: Center(
//             child: Column(
//               children: [
//                 Icon(
//                   Icons.search_off_rounded,
//                   size: 40,
//                   color: Colors.grey.shade400,
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'No results found',
//                   style: AppTextStyles.fieldLabel(
//                     context,
//                   ).copyWith(color: Colors.grey.shade600),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   'Try adjusting your search terms',
//                   style: AppTextStyles.termsText(
//                     context,
//                   ).copyWith(color: Colors.grey.shade400, fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }

//       // Show results
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Section header
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   'Search Results',
//                   style: AppTextStyles.fieldLabel(
//                     context,
//                   ).copyWith(fontWeight: FontWeight.w600, fontSize: 14),
//                 ),
//                 Text(
//                   '${searchController.searchResults.length} products',
//                   style: AppTextStyles.termsText(
//                     context,
//                   ).copyWith(fontSize: 12, color: AppColors.textGray),
//                 ),
//               ],
//             ),
//           ),
//           const Divider(height: 1),
//           Expanded(
//             child: ListView.builder(
//               padding: const EdgeInsets.symmetric(vertical: 4),
//               itemCount: searchController.searchResults.length,
//               itemBuilder: (context, index) {
//                 final product = searchController.searchResults[index];
//                 return _SuggestionItem(product: product);
//               },
//             ),
//           ),
//         ],
//       );
//     });
//   }
// }

// class _SuggestionItem extends StatelessWidget {
//   final SearchProduct product;
//   const _SuggestionItem({required this.product});

//   @override
//   Widget build(BuildContext context) {
//     final searchController = Get.find<AppSearchController>(); // Updated type

//     return InkWell(
//       onTap: () {
//         searchController.navigateToProduct(product);
//       },
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(color: Colors.grey.shade100, width: 1),
//           ),
//         ),
//         child: Row(
//           children: [
//             // Product Image
//             Container(
//               width: 50,
//               height: 50,
//               decoration: BoxDecoration(
//                 color: AppColors.fieldFill,
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: _isValidImageUrl(product.masterImage)
//                   ? ClipRRect(
//                       borderRadius: BorderRadius.circular(6),
//                       child: Image.network(
//                         product.masterImage,
//                         fit: BoxFit.contain,
//                         width: double.infinity,
//                         height: double.infinity,
//                         errorBuilder: (_, __, ___) => const Icon(
//                           Icons.inventory_2_outlined,
//                           size: 30,
//                           color: Colors.black26,
//                         ),
//                       ),
//                     )
//                   : const Icon(
//                       Icons.inventory_2_outlined,
//                       size: 30,
//                       color: Colors.black26,
//                     ),
//             ),
//             const SizedBox(width: 12),
//             // Product Info
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   if (product.brandName.isNotEmpty)
//                     Text(
//                       product.brandName,
//                       maxLines: 1,
//                       overflow: TextOverflow.ellipsis,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: AppColors.textGray,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   Text(
//                     product.productName,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: AppTextStyles.fieldLabel(
//                       context,
//                     ).copyWith(color: AppColors.textDark, fontSize: 13),
//                   ),
//                   const SizedBox(height: 4),
//                   Row(
//                     children: [
//                       Text(
//                         '₹${product.retailPrice.toStringAsFixed(0)}',
//                         style: const TextStyle(
//                           fontWeight: FontWeight.w700,
//                           fontSize: 14,
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       Container(
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 6,
//                           vertical: 1,
//                         ),
//                         decoration: BoxDecoration(
//                           color: product.stock > 0
//                               ? AppColors.primaryGreen.withOpacity(0.1)
//                               : AppColors.errorRed.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(
//                           product.stock > 0 ? 'In Stock' : 'Out of Stock',
//                           style: TextStyle(
//                             fontSize: 9,
//                             color: product.stock > 0
//                                 ? AppColors.primaryGreen
//                                 : AppColors.errorRed,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//             Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
// }
