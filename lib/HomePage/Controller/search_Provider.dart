// import 'dart:async';

// import 'package:brikle/ApiConfiguration/apiservice.dart';
// import 'package:brikle/HomePage/Model/search_model.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// // Renamed to avoid conflict with Flutter's SearchController
// class AppSearchController extends GetxController {
//   final RxList<SearchProduct> searchResults = <SearchProduct>[].obs;
//   final RxBool isLoading = false.obs;
//   final RxString searchQuery = ''.obs;
//   final RxBool isSearching = false.obs;
//   final RxBool isFocused = false.obs;
//   final TextEditingController textController = TextEditingController();

//   // Debounce timer for search
//   Timer? _debounceTimer;
//   static const Duration _debounceDuration = Duration(milliseconds: 300);

//   @override
//   void onClose() {
//     _debounceTimer?.cancel();
//     textController.dispose();
//     super.onClose();
//   }

//   void onSearchTextChanged(String query) {
//     searchQuery.value = query;
    
//     // Cancel any pending search
//     _debounceTimer?.cancel();
    
//     if (query.isEmpty) {
//       searchResults.clear();
//       isSearching.value = false;
//       return;
//     }

//     isSearching.value = true;
    
//     // Debounce the search
//     _debounceTimer = Timer(_debounceDuration, () {
//       _performSearch(query);
//     });
//   }

//   Future<void> _performSearch(String query) async {
//     try {
//       isLoading.value = true;
//       final results = await ApiService.globalSearch(query);
//       searchResults.value = results
//           .map((e) => SearchProduct.fromJson(e as Map<String, dynamic>))
//           .toList();
//     } catch (e) {
//       debugPrint('[AppSearchController] Error performing search: $e');
//       searchResults.clear();
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   void clearSearch() {
//     searchQuery.value = '';
//     searchResults.clear();
//     isSearching.value = false;
//     isFocused.value = false;
//     textController.clear();
//     _debounceTimer?.cancel();
//   }

//   void setFocus(bool focused) {
//     isFocused.value = focused;
//     if (!focused && searchQuery.isEmpty) {
//       searchResults.clear();
//       isSearching.value = false;
//     }
//   }

//   void navigateToProduct(SearchProduct product) {
//     // Navigate to product detail page
//     // Get.to(() => ProductDetailScreen(product: product));
//     clearSearch();
//   }
// }