import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Wishlist/Model/wishlist_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WishlistController extends GetxController {
  final RxList<WishlistItem> items = <WishlistItem>[].obs;
  final RxBool isLoading = true.obs;
  final RxSet<int> _wishlistedVariantIds = <int>{}.obs;
  final Set<int> _pending = {};

  bool isWishlisted(int variantId) => _wishlistedVariantIds.contains(variantId);

  @override
  void onInit() {
    super.onInit();
    debugPrint('[Wishlist] onInit — calling fetchWishlist()');
    fetchWishlist();
  }

  // GET /api/wishlist/
  Future<void> fetchWishlist() async {
    debugPrint('[Wishlist] fetchWishlist() start');
    isLoading.value = true;
    try {
      final response = await ApiService.getWishlist();
      debugPrint(
        '[Wishlist] fetchWishlist raw response type: ${response.runtimeType}',
      );

      final List raw = response is List
          ? response
          : ((response as Map)['wishlist_items'] as List? ?? []);
      debugPrint('[Wishlist] fetchWishlist raw item count: ${raw.length}');

      final parsed = raw
          .whereType<Map<String, dynamic>>()
          .map(WishlistItem.fromJson)
          .toList();

      items.value = parsed;
      _wishlistedVariantIds.value = parsed.map((e) => e.variantId).toSet();

      debugPrint(
        '[Wishlist] fetchWishlist success — '
        'items: ${parsed.map((e) => "(id:${e.id}, variantId:${e.variantId})").toList()}',
      );
      debugPrint(
        '[Wishlist] _wishlistedVariantIds now: $_wishlistedVariantIds',
      );
    } on ApiException catch (e) {
      debugPrint('[Wishlist] fetchWishlist failed: ${e.message}');
      Get.snackbar(
        'Could not load wishlist',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, st) {
      debugPrint('[Wishlist] fetchWishlist unexpected: $e');
      debugPrint('[Wishlist] stack: $st');
    } finally {
      isLoading.value = false;
      debugPrint('[Wishlist] fetchWishlist() end — isLoading=false');
    }
  }

  // POST /api/wishlist/  |  DELETE /api/wishlist/{id}/
  Future<void> toggle(int variantId) async {
    debugPrint('[Wishlist] toggle() called for variantId=$variantId');

    if (_pending.contains(variantId)) {
      debugPrint(
        '[Wishlist] toggle() ignored — variantId=$variantId already pending',
      );
      return;
    }
    _pending.add(variantId);

    final wasWishlisted = _wishlistedVariantIds.contains(variantId);
    debugPrint('[Wishlist] variantId=$variantId wasWishlisted=$wasWishlisted');

    // Optimistic UI
    if (wasWishlisted) {
      _wishlistedVariantIds.remove(variantId);
    } else {
      _wishlistedVariantIds.add(variantId);
    }
    debugPrint(
      '[Wishlist] optimistic update applied. Set now: $_wishlistedVariantIds',
    );

    try {
      if (wasWishlisted) {
        final entry = items.firstWhereOrNull((i) => i.variantId == variantId);
        debugPrint(
          '[Wishlist] removing — matched entry: '
          '${entry == null ? "NONE FOUND" : "(id:${entry.id}, variantId:${entry.variantId})"}',
        );

        if (entry != null) {
          debugPrint(
            '[Wishlist] calling removeFromWishlist(variantId: $variantId)',
          );
          await ApiService.removeFromWishlist(
            variantId: variantId,
          ); // ← was: wishlistId: entry.id
          items.removeWhere((i) => i.variantId == variantId);
          debugPrint('[Wishlist] remove succeeded for variantId=$variantId');
        } else {
          debugPrint(
            '[Wishlist] WARNING: wasWishlisted=true but no matching entry in items — '
            'local state was already out of sync before this call',
          );
        }
      } else {
        debugPrint('[Wishlist] calling addToWishlist(variantId: $variantId)');
        await ApiService.addToWishlist(variantId: variantId);
        debugPrint('[Wishlist] add succeeded — refreshing list');
        await fetchWishlist();
      }
    } on ApiException catch (e) {
      debugPrint(
        '[Wishlist] toggle FAILED for variantId=$variantId '
        '(wasWishlisted=$wasWishlisted): ${e.message}',
      );
      debugPrint('[Wishlist] resyncing with server truth via fetchWishlist()');
      await fetchWishlist();
      Get.snackbar(
        'Wishlist error',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, st) {
      debugPrint(
        '[Wishlist] toggle unexpected error for variantId=$variantId: $e',
      );
      debugPrint('[Wishlist] stack: $st');
      await fetchWishlist();
    } finally {
      _pending.remove(variantId);
      debugPrint('[Wishlist] toggle() finished for variantId=$variantId');
    }
  }

  Future<void> removeItem(WishlistItem item) async {
    debugPrint(
      '[Wishlist] removeItem() called for (id:${item.id}, variantId:${item.variantId})',
    );
    await toggle(item.variantId);
  }

  // Move to Cart: add to cart then remove from wishlist
  Future<void> moveToCart(WishlistItem item) async {
    debugPrint(
      '[Wishlist] moveToCart() called for (id:${item.id}, variantId:${item.variantId})',
    );
    try {
      final cartController = Get.find<CartController>();
      debugPrint(
        '[Wishlist] adding variantId=${item.variantId} to cart, qty=1',
      );
      await cartController.addToCart(variantId: item.variantId, quantity: 1);
      debugPrint('[Wishlist] cart add succeeded — now removing from wishlist');
      await toggle(item.variantId);
    } on ApiException catch (e) {
      debugPrint('[Wishlist] moveToCart failed: ${e.message}');
      Get.snackbar(
        'Could not move to cart',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e, st) {
      debugPrint('[Wishlist] moveToCart unexpected: $e');
      debugPrint('[Wishlist] stack: $st');
    }
  }
}
