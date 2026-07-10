// import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
// import 'package:brikle/ApiConfiguration/apiconfig.dart';
// import 'package:brikle/ApiConfiguration/apiservice.dart';
// import 'package:brikle/Wishlist/Model/wishlist_model.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// /// CONTROLLER — manages wishlist state across the whole app.
// ///
// /// Register once in main.dart or your binding:
// ///   Get.put(WishlistController(), permanent: true);
// ///
// /// Then use from anywhere:
// ///   final wl = Get.find<WishlistController>();
// ///   wl.toggle(variantId);
// ///   wl.isWishlisted(variantId);
// class WishlistController extends GetxController {
//   // ── State ──────────────────────────────────────────────────────────────
//   final RxList<WishlistItem> items = <WishlistItem>[].obs;
//   final RxBool isLoading = true.obs;

//   // Set of variantIds currently in the wishlist.
//   // Used by WishlistHeart widgets to show filled/outline heart instantly
//   // without reading the full items list every time.
//   final RxSet<int> _wishlistedVariantIds = <int>{}.obs;

//   /// Returns true if the given variantId is in the wishlist.
//   bool isWishlisted(int variantId) =>
//       _wishlistedVariantIds.contains(variantId);

//   // Debounce set — prevents double-taps firing two API calls
//   final Set<int> _pending = {};

//   @override
//   void onInit() {
//     super.onInit();
//     fetchWishlist();
//   }

//   // ── Fetch ──────────────────────────────────────────────────────────────
//   // GET /api/wishlist/
//   // Response: { "wishlist_items": [ { "id":5, "variant":1, ... } ] }
//   Future<void> fetchWishlist() async {
//     isLoading.value = true;
//     try {
//       final response = await ApiService.getWishlist();
//       final raw = response['wishlist_items'] as List? ?? [];
//       final parsed = raw
//           .whereType<Map<String, dynamic>>()
//           .map(WishlistItem.fromJson)
//           .toList();
//       items.value = parsed;
//       _wishlistedVariantIds.value = parsed.map((e) => e.variantId).toSet();
//     } on ApiException catch (e) {
//       debugPrint('[WishlistController] fetchWishlist failed: ${e.message}');
//       Get.snackbar('Could not load wishlist', e.message,
//           snackPosition: SnackPosition.BOTTOM);
//     } catch (e) {
//       debugPrint('[WishlistController] fetchWishlist unexpected: $e');
//     } finally {
//       isLoading.value = false;
//     }
//   }

//   // ── Toggle (add / remove) ──────────────────────────────────────────────
//   // Add:    POST /api/wishlist/         body: { "variant": variantId }
//   // Remove: DELETE /api/wishlist/{id}/
//   Future<void> toggle(int variantId) async {
//     if (_pending.contains(variantId)) return; // debounce
//     _pending.add(variantId);

//     final wasWishlisted = _wishlistedVariantIds.contains(variantId);

//     // Optimistic UI — heart flips immediately
//     if (wasWishlisted) {
//       _wishlistedVariantIds.remove(variantId);
//     } else {
//       _wishlistedVariantIds.add(variantId);
//     }

//     try {
//       if (wasWishlisted) {
//         // Find the entry id for DELETE /api/wishlist/{id}/
//         final entry =
//             items.firstWhereOrNull((i) => i.variantId == variantId);
//         if (entry != null) {
//           await ApiService.removeFromWishlist(wishlistId: entry.id);
//           items.removeWhere((i) => i.variantId == variantId);
//         }
//       } else {
//         // POST returns only { "message": "Add to wishlist!" } — no item data.
//         // So we re-fetch to get the new entry with its id.
//         await ApiService.addToWishlist(variantId: variantId);
//         await fetchWishlist(); // reconcile to get the new item's id
//       }
//     } on ApiException catch (e) {
//       // Revert optimistic update on failure
//       if (wasWishlisted) {
//         _wishlistedVariantIds.add(variantId);
//       } else {
//         _wishlistedVariantIds.remove(variantId);
//       }
//       debugPrint('[WishlistController] toggle failed: ${e.message}');
//       Get.snackbar('Wishlist error', e.message,
//           snackPosition: SnackPosition.BOTTOM);
//     } catch (e) {
//       if (wasWishlisted) {
//         _wishlistedVariantIds.add(variantId);
//       } else {
//         _wishlistedVariantIds.remove(variantId);
//       }
//       debugPrint('[WishlistController] toggle unexpected: $e');
//     } finally {
//       _pending.remove(variantId);
//     }
//   }

//   // ── Move to cart ───────────────────────────────────────────────────────
//   Future<void> moveToCart(WishlistItem item) async {
//     try {
//       final cartController = Get.find<CartController>();
//       await cartController.addToCart(variantId: item.variantId, quantity: 1);
//       await toggle(item.variantId); // removes from wishlist after adding to cart
//     } on ApiException catch (e) {
//       debugPrint('[WishlistController] moveToCart failed: ${e.message}');
//       Get.snackbar('Could not move to cart', e.message,
//           snackPosition: SnackPosition.BOTTOM);
//     } catch (e) {
//       debugPrint('[WishlistController] moveToCart unexpected: $e');
//     }
//   }
// }