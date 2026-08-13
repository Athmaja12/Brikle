// lib/Product/Controller/productdetails_controller.dart

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

  // NEW: Product offer from API
  final Rx<ProductOffer?> productOffer = Rx<ProductOffer?>(null);

  final RxInt selectedImageIndex = 0.obs;
  final RxBool isWishlisted = false.obs;
  final RxInt cartQuantity = 0.obs;

  final RxBool highlightsExpanded = false.obs;
  final RxBool descriptionExpanded = false.obs;
  final RxBool faqsExpanded = false.obs;
  final RxBool returnsExpanded = false.obs;

  final RxList<SmartSuggestion> suggestedProducts = <SmartSuggestion>[].obs;

  // NEW: Computed price with offer
  double get discountedPrice {
    final offer = productOffer.value;
    if (offer == null) return product.price;
    return product.price * (1 - offer.discountPercentage / 100);
  }

  // NEW: Original price (MRP) for strike-through
  double get originalPriceValue {
    final offer = productOffer.value;
    if (offer == null) return product.price;
    return product.price; // The price from product is the retail price
  }

  // NEW: Discount percentage
  int get discountPercentageValue {
    final offer = productOffer.value;
    if (offer == null) return 0;
    return offer.discountPercentage.toInt();
  }

  // NEW: Check if offer is available
  bool get hasOffer => productOffer.value != null;

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

  Future<void> refresh() async {
    isLoading.value = true;
    try {
      final response = await ApiService.getMaterialDetails(product.materialId);
      final materialDetail = MaterialDetail.fromJson(response);
      detail.value = materialDetail;
      
      // NEW: Set product offer from API
      productOffer.value = materialDetail.offer;
      
      suggestedProducts.assignAll(
        await ApiService.getMaterialSuggestions(product.materialId),
      );
      _loadOffers();

      if (activeProduct.value.variantId == 0) {
        final resolved = await ApiService.getSuggestedProductDetail(
          product.materialId,
        );
        if (resolved != null) {
          activeProduct.value = resolved;
        }
      }

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
  void toggleHighlights() => highlightsExpanded.value = !highlightsExpanded.value;
  void toggleDescription() => descriptionExpanded.value = !descriptionExpanded.value;
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