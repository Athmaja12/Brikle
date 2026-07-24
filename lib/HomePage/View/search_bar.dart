// import 'package:brikle/AppStyle/appcolors.dart';
// import 'package:brikle/AppStyle/appstyle.dart';
// import 'package:brikle/AppStyle/responsive.dart';
// import 'package:brikle/HomePage/Controller/search_provider.dart'; // Updated import
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class FlipkartSearchBar extends StatefulWidget {
//   final bool isHomePage;
//   final VoidCallback? onSearchTap;

//   const FlipkartSearchBar({
//     super.key,
//     this.isHomePage = true,
//     this.onSearchTap,
//   });

//   @override
//   State<FlipkartSearchBar> createState() => _FlipkartSearchBarState();
// }

// class _FlipkartSearchBarState extends State<FlipkartSearchBar> {
//   late final AppSearchController searchController; // Updated type
//   final FocusNode _focusNode = FocusNode();

//   @override
//   void initState() {
//     super.initState();
//     searchController = Get.find<AppSearchController>(); // Updated find

//     _focusNode.addListener(() {
//       searchController.setFocus(_focusNode.hasFocus);
//     });
//   }

//   @override
//   void dispose() {
//     _focusNode.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: Responsive.height(context, 44),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: AppColors.inputBorder),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           const SizedBox(width: 12),
//           Icon(Icons.search, color: AppColors.primaryGreen, size: 20),
//           const SizedBox(width: 8),
//           Expanded(
//             child: TextField(
//               controller: searchController.textController,
//               focusNode: _focusNode,
//               decoration: InputDecoration(
//                 hintText: widget.isHomePage
//                     ? "Search for 'Asian Paints'"
//                     : "Search products...",
//                 hintStyle: AppTextStyles.loginSubtitle(
//                   context,
//                 ).copyWith(fontSize: 14, color: AppColors.textGray),
//                 border: InputBorder.none,
//                 contentPadding: EdgeInsets.zero,
//                 isDense: true,
//               ),
//               onChanged: (value) {
//                 searchController.onSearchTextChanged(value);
//                 if (widget.onSearchTap != null && value.isNotEmpty) {
//                   widget.onSearchTap!();
//                 }
//               },
//               onTap: () {
//                 if (widget.onSearchTap != null) {
//                   widget.onSearchTap!();
//                 }
//               },
//             ),
//           ),
//           Obx(() {
//             if (searchController.searchQuery.isNotEmpty) {
//               return GestureDetector(
//                 onTap: searchController.clearSearch,
//                 child: Container(
//                   padding: const EdgeInsets.all(4),
//                   decoration: const BoxDecoration(shape: BoxShape.circle),
//                   child: Icon(Icons.clear, color: AppColors.textGray, size: 18),
//                 ),
//               );
//             }
//             return const SizedBox.shrink();
//           }),
//           const SizedBox(width: 8),
//         ],
//       ),
//     );
//   }
// }
