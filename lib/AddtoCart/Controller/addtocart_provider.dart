import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Real cart CRUD via API. Coupon/GSTIN/bill-breakdown/cancellation-policy
/// are intentionally static placeholders — no backend for those yet.
class CartController extends GetxController {
  final RxList<CartItem> cartItems = <CartItem>[].obs;
  final RxDouble grandTotal = 0.0.obs;
  final RxBool isLoading = true.obs;

  // ── STATIC placeholders — no API for these yet ──────────────────────
  final RxString couponCode = ''.obs;
  final RxBool gstinAdded = false.obs;
  static const double staticDiscount = 0;
  static const String staticDeliveryChargeLabel = 'FREE';
  static const double staticHandlingCharge = 0;
  // ── END STATIC ───────────────────────────────────────────────────────

  int get itemCount => cartItems.length;
  double get subTotal => grandTotal.value;
  double get total => subTotal - staticDiscount + staticHandlingCharge;

  @override
  void onInit() {
    super.onInit();
    fetchCart();
  }

  Future<void> fetchCart({bool showLoader = true}) async {
    if (showLoader) {
      isLoading.value = true;
    }
    try {
      final response = await ApiService.getCart();
      final parsed = CartResponse.fromJson(response);
      cartItems.value = parsed.items;
      grandTotal.value = parsed.grandTotalWithGst;
    } on ApiException catch (e) {
      debugPrint('[CartController] fetchCart failed: ${e.message}');
      Get.snackbar('Could not load cart', e.message);
    } catch (e) {
      debugPrint('[CartController] fetchCart unexpected error: $e');
    } finally {
      if (showLoader) {
        isLoading.value = false;
      }
    }
  }

  Future<void> addToCart({required int variantId, int quantity = 1}) async {
    try {
      await ApiService.addToCart(variantId: variantId, quantity: quantity);
      await fetchCart();
      Get.snackbar('Added to Cart', 'Item added successfully');
    } on ApiException catch (e) {
      debugPrint('[CartController] addToCart failed: ${e.message}');
      Get.snackbar('Could not add to cart', e.message);
    } catch (e) {
      debugPrint('[CartController] addToCart unexpected error: $e');
    }
  }

  Future<void> updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity < 1) return;

    // Optimistic local update for instant UI feedback
    final index = cartItems.indexWhere((i) => i.variantId == item.variantId);
    if (index != -1) {
      final unitPrice = item.unitPriceWithGst;
      cartItems[index] = item.copyWith(
        quantity: newQuantity,
        totalPriceWithGst: unitPrice * newQuantity,
      );
      cartItems.refresh(); // Notify observers of the change
      _recalculateGrandTotal();
    }

    try {
      await ApiService.updateCartItem(
        variantId: item.variantId,
        quantity: newQuantity,
      );
      await fetchCart(
        showLoader: false,
      ); // reconcile with server truth (tiered pricing may change unit price)
    } on ApiException catch (e) {
      debugPrint('[CartController] updateQuantity failed: ${e.message}');
      Get.snackbar('Could not update quantity', e.message);
      await fetchCart(showLoader: false); // revert optimistic update on failure
    } catch (e) {
      debugPrint('[CartController] updateQuantity unexpected error: $e');
      await fetchCart(showLoader: false); // revert optimistic update on failure
    }
  }

  void increment(CartItem item) => updateQuantity(item, item.quantity + 1);
  void decrement(CartItem item) => updateQuantity(item, item.quantity - 1);

  Future<void> removeItem(CartItem item) async {
    final removed = item;
    cartItems.removeWhere((i) => i.variantId == item.variantId);
    _recalculateGrandTotal();

    try {
      await ApiService.removeCartItem(variantId: removed.variantId);
    } on ApiException catch (e) {
      debugPrint('[CartController] removeItem failed: ${e.message}');
      Get.snackbar('Could not remove item', e.message);
      await fetchCart(); // revert
    } catch (e) {
      debugPrint('[CartController] removeItem unexpected error: $e');
      await fetchCart(showLoader: false); // revert
    }
  }

  /// "Clear" — no bulk-clear endpoint given, so this removes each item
  /// individually via the same DELETE endpoint.
  Future<void> clearCart() async {
    final items = List<CartItem>.from(cartItems);
    cartItems.clear();
    grandTotal.value = 0;
    for (final item in items) {
      try {
        await ApiService.removeCartItem(variantId: item.variantId);
      } catch (e) {
        debugPrint(
          '[CartController] clearCart: failed removing variant ${item.variantId}: $e',
        );
      }
    }
    await fetchCart(showLoader: false);
  }

  void _recalculateGrandTotal() {
    grandTotal.value = cartItems.fold(
      0.0,
      (sum, item) => sum + item.totalPriceWithGst,
    );
  }

  // ── STATIC feature stubs ─────────────────────────────────────────────
  void applyCoupon(String code) {
    couponCode.value = code;
    Get.snackbar('Coupon', 'Coupon feature coming soon');
  }

  void addGstin() {
    gstinAdded.value = true;
    Get.snackbar('GSTIN', 'GSTIN feature coming soon');
  }
}
