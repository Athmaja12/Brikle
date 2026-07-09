// // lib/Wishlist/View/wishlist_screen.dart

// import 'package:brikle/AppStyle/appcolors.dart';
// import 'package:brikle/Category/Controller/category_controller.dart';
// import 'package:brikle/Category/View/categorydetail_screen.dart';
// import 'package:brikle/Wishlist/Controller/wishlist_provider.dart';
// import 'package:brikle/Wishlist/Model/wishlist_model.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';

// class WishlistScreen extends StatelessWidget {
//   const WishlistScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final sw = MediaQuery.of(context).size.width;
//     final hp = sw * 0.04;
//     final WishlistController ctrl = Get.find<WishlistController>();

//     return Scaffold(
//       backgroundColor: const Color(0xFFF3F4F6),
//       body: SafeArea(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildAppBar(context, sw, hp, ctrl),
//             Expanded(
//               child: Obx(() {
//                 if (ctrl.isLoading.value && ctrl.items.isEmpty) {
//                   return const Center(
//                     child: CircularProgressIndicator(
//                       color: AppColors.primaryGreen,
//                     ),
//                   );
//                 }
//                 if (ctrl.items.isEmpty) {
//                   return _EmptyWishlist(sw: sw);
//                 }
//                 return RefreshIndicator(
//                   color: AppColors.primaryGreen,
//                   onRefresh: ctrl.fetchWishlist,
//                   child: ListView.separated(
//                     physics: const AlwaysScrollableScrollPhysics(),
//                     padding: EdgeInsets.fromLTRB(hp, sw * 0.02, hp, hp),
//                     itemCount: ctrl.items.length,
//                     separatorBuilder: (_, __) => SizedBox(height: sw * 0.03),
//                     itemBuilder: (_, i) => _WishlistCard(
//                       sw: sw,
//                       item: ctrl.items[i],
//                       ctrl: ctrl,
//                     ),
//                   ),
//                 );
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAppBar(
//     BuildContext context,
//     double sw,
//     double hp,
//     WishlistController ctrl,
//   ) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: hp, vertical: sw * 0.03),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: () => Get.back(),
//             child: Container(
//               width: sw * 0.1,
//               height: sw * 0.1,
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 shape: BoxShape.circle,
//                 border: Border.all(color: const Color(0xFFE5E7EB)),
//               ),
//               child: Icon(
//                 Icons.arrow_back,
//                 color: AppColors.inputText,
//                 size: sw * 0.05,
//               ),
//             ),
//           ),
//           SizedBox(width: sw * 0.03),
//           Icon(Icons.favorite, color: AppColors.primaryGreen, size: sw * 0.065),
//           SizedBox(width: sw * 0.02),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Text(
//                   'Wishlist',
//                   style: GoogleFonts.manrope(
//                     fontSize: sw * 0.05,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.inputText,
//                   ),
//                 ),
//                 Obx(() => Text(
//                   '${ctrl.items.length} ${ctrl.items.length == 1 ? 'item' : 'items'} saved',
//                   style: GoogleFonts.manrope(
//                     fontSize: sw * 0.028,
//                     color: AppColors.textGray,
//                   ),
//                 )),
//               ],
//             ),
//           ),
//           Obx(() {
//             if (ctrl.items.isEmpty) return const SizedBox.shrink();
//             return GestureDetector(
//               onTap: ctrl.isMovingAll.value ? null : ctrl.moveAllToCart,
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: sw * 0.03,
//                   vertical: sw * 0.022,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryGreen,
//                   borderRadius: BorderRadius.circular(sw * 0.025),
//                 ),
//                 child: ctrl.isMovingAll.value
//                     ? SizedBox(
//                         width: sw * 0.04,
//                         height: sw * 0.04,
//                         child: const CircularProgressIndicator(
//                           strokeWidth: 2,
//                           color: Colors.white,
//                         ),
//                       )
//                     : Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: [
//                           Icon(
//                             Icons.shopping_cart_outlined,
//                             size: sw * 0.035,
//                             color: Colors.white,
//                           ),
//                           SizedBox(width: sw * 0.012),
//                           Text(
//                             'Move All',
//                             style: GoogleFonts.manrope(
//                               fontSize: sw * 0.028,
//                               fontWeight: FontWeight.w600,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ],
//                       ),
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }
// }

// // ── Wishlist Card ──────────────────────────────────────────────────────────────
// class _WishlistCard extends StatelessWidget {
//   final double sw;
//   final WishlistModel item;
//   final WishlistController ctrl;

//   const _WishlistCard({
//     required this.sw,
//     required this.item,
//     required this.ctrl,
//   });

//   /// Tries to find the matching ProductModel from ProductController so
//   /// tapping the card opens the SAME detail screen used elsewhere in the
//   /// app (with full product info: category, price tiers, description...).
//   void _goToProductDetail() {
//     if (!Get.isRegistered<CategoryController>()) return;
//     final categoryCtrl = Get.find<CategoryController>();
//     final match = categoryCtrl.categories.firstWhereOrNull(
//       (c) => c.id == item.categoryId,
//     );
//     if (match != null) {
//       Get.to(() => CategoryDetailScreen(
//             categoryId: match.id,
//             categoryName: match.name,
//           ));
//     } else {
//       Get.snackbar(
//         'Unavailable',
//         'This product could not be opened right now.',
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _goToProductDetail,
//       behavior: HitTestBehavior.opaque,
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(sw * 0.04),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               blurRadius: 10,
//               offset: const Offset(0, 3),
//             ),
//           ],
//         ),
//         child: Padding(
//           padding: EdgeInsets.all(sw * 0.03),
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ── Image ────────────────────────────────────────────────────
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(sw * 0.03),
//                 child: item.productImage != null &&
//                         item.productImage!.isNotEmpty
//                     ? Image.network(
//                         item.productImage!,
//                         width: sw * 0.24,
//                         height: sw * 0.24,
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) => _placeholder(),
//                       )
//                     : _placeholder(),
//               ),
//               SizedBox(width: sw * 0.035),

//               // ── Info ────────────────────────────────────────────────────
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Expanded(
//                           child: Text(
//                             item.productName,
//                             maxLines: 2,
//                             overflow: TextOverflow.ellipsis,
//                             style: GoogleFonts.manrope(
//                               fontSize: sw * 0.036,
//                               fontWeight: FontWeight.w600,
//                               color: AppColors.inputText,
//                               height: 1.3,
//                             ),
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () => ctrl.removeItem(item),
//                           child: Padding(
//                             padding: EdgeInsets.only(
//                               left: sw * 0.02,
//                               top: sw * 0.005,
//                             ),
//                             child: Icon(
//                               Icons.close_rounded,
//                               size: sw * 0.05,
//                               color: AppColors.textGray,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: sw * 0.012),
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.check_circle_rounded,
//                           size: sw * 0.03,
//                           color: item.isActive
//                               ? AppColors.primaryGreen
//                               : Colors.grey,
//                         ),
//                         SizedBox(width: sw * 0.01),
//                         Text(
//                           item.isActive ? 'In stock' : 'Unavailable',
//                           style: GoogleFonts.manrope(
//                             fontSize: sw * 0.026,
//                             fontWeight: FontWeight.w500,
//                             color: item.isActive
//                                 ? AppColors.primaryGreen
//                                 : AppColors.textGray,
//                           ),
//                         ),
//                       ],
//                     ),
//                     SizedBox(height: sw * 0.014),
//                     Text(
//                       '₹${item.price.toStringAsFixed(0)}',
//                       style: GoogleFonts.manrope(
//                         fontSize: sw * 0.042,
//                         fontWeight: FontWeight.w700,
//                         color: AppColors.inputText,
//                       ),
//                     ),
//                     SizedBox(height: sw * 0.03),

//                     // ── Move to cart pill ──────────────────────────────
//                     GestureDetector(
//                       onTap: () => ctrl.moveToCart(item),
//                       child: Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: sw * 0.035,
//                           vertical: sw * 0.02,
//                         ),
//                         decoration: BoxDecoration(
//                           color: AppColors.primaryGreen,
//                           borderRadius: BorderRadius.circular(sw * 0.025),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min,
//                           children: [
//                             Icon(
//                               Icons.shopping_cart_outlined,
//                               size: sw * 0.034,
//                               color: Colors.white,
//                             ),
//                             SizedBox(width: sw * 0.015),
//                             Text(
//                               'Move to Cart',
//                               style: GoogleFonts.manrope(
//                                 fontSize: sw * 0.028,
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _placeholder() => Container(
//         width: sw * 0.24,
//         height: sw * 0.24,
//         decoration: BoxDecoration(
//           color: const Color(0xFFF3F4F6),
//           borderRadius: BorderRadius.circular(sw * 0.03),
//         ),
//         child: Icon(
//           Icons.inventory_2_outlined,
//           size: sw * 0.09,
//           color: Colors.black12,
//         ),
//       );
// }

// // ── Empty State ───────────────────────────────────────────────────────────────
// class _EmptyWishlist extends StatelessWidget {
//   final double sw;
//   const _EmptyWishlist({required this.sw});

//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: sw * 0.32,
//               height: sw * 0.32,
//               decoration: const BoxDecoration(
//                 color: Color(0xFFFEF2F2),
//                 shape: BoxShape.circle,
//               ),
//               alignment: Alignment.center,
//               child: Icon(
//                 Icons.favorite_border_rounded,
//                 size: sw * 0.14,
//                 color: const Color(0xFFFCA5A5),
//               ),
//             ),
//             SizedBox(height: sw * 0.05),
//             Text(
//               'Your wishlist is empty',
//               style: GoogleFonts.manrope(
//                 fontSize: sw * 0.045,
//                 fontWeight: FontWeight.w700,
//                 color: AppColors.inputText,
//               ),
//             ),
//             SizedBox(height: sw * 0.015),
//             Text(
//               'Tap the heart icon on any product to save it here for later',
//               textAlign: TextAlign.center,
//               style: GoogleFonts.manrope(
//                 fontSize: sw * 0.032,
//                 color: AppColors.textGray,
//                 height: 1.5,
//               ),
//             ),
//             SizedBox(height: sw * 0.04),
//             GestureDetector(
//               onTap: () => Get.back(),
//               child: Container(
//                 padding: EdgeInsets.symmetric(
//                   horizontal: sw * 0.08,
//                   vertical: sw * 0.032,
//                 ),
//                 decoration: BoxDecoration(
//                   color: AppColors.primaryGreen,
//                   borderRadius: BorderRadius.circular(sw * 0.03),
//                 ),
//                 child: Text(
//                   'Browse Products',
//                   style: GoogleFonts.manrope(
//                     fontSize: sw * 0.034,
//                     fontWeight: FontWeight.w600,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }