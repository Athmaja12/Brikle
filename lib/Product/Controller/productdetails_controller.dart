import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/Model/productdetails_model.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailController extends GetxController {
  final CategoryProductItem product;
  // Optional — only ever populated when navigation originates from a
  // deal/bestseller card that actually carries discount pricing.
  // CategoryProductItem itself has no discount fields (confirmed against
  // categorydetail_model.dart), so plain category/search navigation will
  // correctly show no strike-through at all — that's expected, not a bug.
  final double? originalPrice;
  final int? discountPercent;

  ProductDetailController({
    required this.product,
    this.originalPrice,
    this.discountPercent,
  });

  final RxBool isLoading = true.obs;
  final Rx<MaterialDetail?> detail = Rx<MaterialDetail?>(null);
  late final Rx<CategoryProductItem> activeProduct = product.obs;

  // ── Offers ──────────────────────────────────────────────────────────
  final RxList<CouponModel> offers = <CouponModel>[].obs;
  final RxBool isLoadingOffers = false.obs;

  final RxInt selectedImageIndex = 0.obs;
  final RxBool isWishlisted = false.obs;
  final RxInt cartQuantity = 0.obs;

  final RxBool highlightsExpanded = false.obs;
  final RxBool descriptionExpanded = false.obs;
  final RxBool faqsExpanded = false.obs;
  final RxBool returnsExpanded = false.obs;

  final RxList<SmartSuggestion> suggestedProducts = <SmartSuggestion>[].obs;

  List<String> get galleryImages {
    final d = detail.value;
    if (d == null) return [product.imageUrl];
    final all = [
      if (d.masterImage.isNotEmpty) d.masterImage,
      ...d.galleryImages,
    ];
    return all.isEmpty ? [product.imageUrl] : all;
  }

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  /// Public refresh() — used on init AND by RefreshIndicator (pull to
  /// refresh) on the product detail page. Renamed from the old private
  /// _load() so the view can call it directly.
  Future<void> refresh() async {
    isLoading.value = true;
    try {
      final response = await ApiService.getMaterialDetails(product.materialId);
      detail.value = MaterialDetail.fromJson(response);
      suggestedProducts.assignAll(
        await ApiService.getMaterialSuggestions(product.materialId),
      );
      _loadOffers();

      // Placeholder from a "Suggested for you" tap has no real variant —
      // resolve it into a full priced product now, under this screen's
      // own loading state.
      if (activeProduct.value.variantId == 0) {
        final resolved = await ApiService.getSuggestedProductDetail(
          product.materialId,
        );
        if (resolved != null) {
          activeProduct.value = resolved;
        }
      }

      // Re-sync cart quantity in case it changed elsewhere (e.g. user
      // adjusted quantity on the Cart screen, then pulled to refresh here).
      final cart = Get.find<CartController>();
      final item = cart.cartItems.firstWhereOrNull(
        (i) => i.variantId == activeProduct.value.variantId,
      );
      cartQuantity.value = item?.quantity ?? 0;
    } on ApiException catch (e) {
      debugPrint('[ProductDetailController] failed: ${e.message}');
      Get.snackbar('Could not load product', e.message);
    } catch (e) {
      debugPrint('[ProductDetailController] unexpected error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Loads the user's available coupons for the Offers preview card.
  /// Reuses the exact same source as Cart's coupon list — no new backend
  /// endpoint needed. Shown here purely as a preview; applying a coupon
  /// still happens in Cart, same as before.
  Future<void> _loadOffers() async {
    isLoadingOffers.value = true;
    try {
      
      final coupons = await ApiService.getMyCoupons();
      offers.assignAll(coupons.where((c) => c.isValid));
    } catch (e) {
      debugPrint('[ProductDetailController] _loadOffers failed: $e');
    } finally {
      isLoadingOffers.value = false;
    }
  }

  /// Tapping a bulk-pricing tier sets the cart quantity directly to that

  /// Tapping a bulk-pricing tier sets the cart quantity directly to that
  /// tier's minQty — same UX as the Cart page's bulk-pricing sheet.
  Future<void> applyBulkTier(int minQty) async {
    final cart = Get.find<CartController>();
    final variantId = activeProduct.value.variantId;

    if (cartQuantity.value == 0) {
      cartQuantity.value = minQty;
      await cart.addToCart(variantId: variantId, quantity: minQty);
      return;
    }

    final item = cart.cartItems.firstWhereOrNull(
      (i) => i.variantId == variantId,
    );
    if (item == null) {
      cartQuantity.value = minQty;
      await cart.addToCart(variantId: variantId, quantity: minQty);
      return;
    }

    cartQuantity.value = minQty;
    await cart.updateQuantity(item, minQty);
  }

  void selectImage(int index) => selectedImageIndex.value = index;
  void toggleWishlist() => isWishlisted.value = !isWishlisted.value;

  void toggleHighlights() =>
      highlightsExpanded.value = !highlightsExpanded.value;
  void toggleDescription() =>
      descriptionExpanded.value = !descriptionExpanded.value;
  void toggleFaqs() => faqsExpanded.value = !faqsExpanded.value;
  void toggleReturns() => returnsExpanded.value = !returnsExpanded.value;

  Future<void> addToCart() async {
    cartQuantity.value = 1;
    await Get.find<CartController>().addToCart(
      variantId: activeProduct.value.variantId,
      quantity: cartQuantity.value,
    );
  }

  Future<void> incrementQuantity() async {
    final cart = Get.find<CartController>();
    final variantId = activeProduct.value.variantId;
    final item = cart.cartItems.firstWhereOrNull(
      (i) => i.variantId == variantId,
    );
    if (item == null) {
      cartQuantity.value++;
      return;
    }
    cartQuantity.value = item.quantity + 1;
    await cart.updateQuantity(item, cartQuantity.value);
  }

  Future<void> decrementQuantity() async {
    final cart = Get.find<CartController>();
    final variantId = activeProduct.value.variantId;
    final item = cart.cartItems.firstWhereOrNull(
      (i) => i.variantId == variantId,
    );
    if (item == null) {
      cartQuantity.value = 0;
      return;
    }

    if (item.quantity <= 1) {
      cartQuantity.value = 0;
      await cart.removeItem(item);
    } else {
      cartQuantity.value = item.quantity - 1;
      await cart.updateQuantity(item, cartQuantity.value);
    }
  }

  /// Called when the user taps a "Suggested for you" card. Navigates
  /// immediately using a placeholder built from the suggestion (no
  /// price/variant yet); the new screen's own loading state resolves the
  /// real priced product via refresh().
  void openSuggestion(BuildContext context, SmartSuggestion suggestion) {
    final placeholder = CategoryProductItem(
      variantId: 0,
      materialId: suggestion.id,
      name: suggestion.name,
      imageUrl: suggestion.imageUrl,
      brandName: suggestion.brandName,
      price: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: placeholder),
      ),
    );
  }
}
