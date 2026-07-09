// lib/Wishlist/Controller/wishlist_provider.dart

import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Wishlist/Model/wishlist_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WishlistController extends GetxController {
  final RxList<WishlistModel> items = <WishlistModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isMovingAll = false.obs;

  /// Tracks per-product in-flight requests so rapid double-taps on the
  /// heart icon don't fire duplicate add/remove calls.
  final RxSet<int> _pendingProductIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[WishlistController] onInit');
    fetchWishlist();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  bool isWished(int productId) =>
      items.any((w) => w.productId == productId && w.isActive);

  WishlistModel? _entryForProduct(int productId) {
    try {
      return items.firstWhere((w) => w.productId == productId);
    } catch (_) {
      return null;
    }
  }

  bool isPending(int productId) => _pendingProductIds.contains(productId);

  // ══════════════════════════════════════════════════════════════════════════
  // FETCH
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> fetchWishlist() async {
    debugPrint('[WishlistController] fetchWishlist()');
    isLoading.value = true;
    try {
      final response = await ApiService.getWishlist();
      items.assignAll(
        response.map((e) => WishlistModel.fromJson(e as Map<String, dynamic>)),
      );
      debugPrint('[WishlistController] fetched ${items.length} items');
    } on ApiException catch (e) {
      debugPrint(
        '[WishlistController] fetchWishlist ApiException → ${e.message}',
      );
    } catch (e) {
      debugPrint('[WishlistController] fetchWishlist unexpected → $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TOGGLE (used by heart icons everywhere)
  // ══════════════════════════════════════════════════════════════════════════

  /// Adds if not wished, removes if already wished. Optimistic UI update
  /// with rollback on failure.
  Future<void> toggleWishlist(int productId) async {
    if (_pendingProductIds.contains(productId)) return;
    _pendingProductIds.add(productId);

    final existing = _entryForProduct(productId);

    try {
      if (existing != null) {
        // ── Remove ──────────────────────────────────────────────────────
        items.removeWhere((w) => w.productId == productId);
        await ApiService.removeFromWishlist(productId: existing.productId);
        debugPrint('[WishlistController] removed product $productId');
      } else {
        // ── Add ─────────────────────────────────────────────────────────
        final response = await ApiService.addToWishlist(productId: productId);
        final newItem = WishlistModel.fromJson(response);
        items.add(newItem);
        debugPrint('[WishlistController] added product $productId');
      }
    } on ApiException catch (e) {
      debugPrint('[WishlistController] toggle ApiException → ${e.message}');
      // Rollback by re-syncing from server
      await fetchWishlist();
      Get.snackbar('Wishlist', e.message);
    } catch (e) {
      debugPrint('[WishlistController] toggle unexpected → $e');
      await fetchWishlist();
      Get.snackbar('Wishlist', 'Something went wrong. Please try again.');
    } finally {
      _pendingProductIds.remove(productId);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // REMOVE (explicit, used on the wishlist page's remove button)
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> removeItem(WishlistModel item) async {
    debugPrint('[WishlistController] removeItem(${item.id})');
    final backup = items.toList();
    items.removeWhere((w) => w.id == item.id);
    try {
      await ApiService.removeFromWishlist(productId: item.productId);
    } on ApiException catch (e) {
      items.assignAll(backup);
      Get.snackbar('Error', e.message);
    } catch (e) {
      items.assignAll(backup);
      Get.snackbar('Error', 'Failed to remove item. Please try again.');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MOVE TO CART
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> moveToCart(WishlistModel item) async {
    debugPrint('[WishlistController] moveToCart(${item.id})');
    final backup = items.toList();
    items.removeWhere((w) => w.id == item.id);
    try {
      await ApiService.moveWishlistItemToCart(productId: item.productId);
      Get.snackbar('Moved to Cart', '${item.productName} added to your cart.');
    } on ApiException catch (e) {
      items.assignAll(backup);
      Get.snackbar('Error', e.message);
    } catch (e) {
      items.assignAll(backup);
      Get.snackbar('Error', 'Failed to move item to cart. Please try again.');
    }
  }

  Future<void> moveAllToCart() async {
    if (items.isEmpty) return;
    debugPrint('[WishlistController] moveAllToCart()');
    isMovingAll.value = true;
    final backup = items.toList();
    try {
      await ApiService.moveAllWishlistToCart();
      items.clear();
      Get.snackbar('Success', 'All items moved to cart.');
    } on ApiException catch (e) {
      items.assignAll(backup);
      Get.snackbar('Error', e.message);
    } catch (e) {
      items.assignAll(backup);
      Get.snackbar('Error', 'Failed to move items. Please try again.');
    } finally {
      isMovingAll.value = false;
    }
  }

  @override
  void onClose() {
    debugPrint('[WishlistController] onClose');
    super.onClose();
  }
}
