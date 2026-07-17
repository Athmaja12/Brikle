import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/Model/productdetails_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailController extends GetxController {
  final CategoryProductItem product;
  ProductDetailController({required this.product});

  final RxBool isLoading = true.obs;
  final Rx<MaterialDetail?> detail = Rx<MaterialDetail?>(null);

  final RxInt selectedImageIndex = 0.obs;
  final RxBool isWishlisted = false.obs;
  final RxInt cartQuantity = 0.obs;

  final RxBool highlightsExpanded = false.obs;
  final RxBool descriptionExpanded = false.obs;
  final RxBool faqsExpanded = false.obs;
  final RxBool returnsExpanded = false.obs;

  final List<CategoryProductItem> suggestedProducts = const [
    CategoryProductItem(
      variantId: 901,
      materialId: 901,
      name: 'Ultratech PPC Cement, 50 Kg Bag',
      imageUrl: '',
      price: 1199,
    ),
    CategoryProductItem(
      variantId: 902,
      materialId: 902,
      name: 'Ultratech PPC Cement, 50 Kg Bag',
      imageUrl: '',
      price: 1199,
    ),
  ];

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

      // Re-sync cart quantity in case it changed elsewhere (e.g. user
      // adjusted quantity on the Cart screen, then pulled to refresh here).
      final cart = Get.find<CartController>();
      final item = cart.cartItems.firstWhereOrNull(
        (i) => i.variantId == product.variantId,
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

  /// Tapping a bulk-pricing tier sets the cart quantity directly to that
/// tier's minQty — same UX as the Cart page's bulk-pricing sheet.
Future<void> applyBulkTier(int minQty) async {
  final cart = Get.find<CartController>();

  if (cartQuantity.value == 0) {
    // Not in cart yet — add it fresh at the tier quantity.
    cartQuantity.value = minQty;
    await cart.addToCart(variantId: product.variantId, quantity: minQty);
    return;
  }

  final item = cart.cartItems.firstWhereOrNull(
    (i) => i.variantId == product.variantId,
  );
  if (item == null) {
    cartQuantity.value = minQty;
    await cart.addToCart(variantId: product.variantId, quantity: minQty);
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
      variantId: product.variantId,
      quantity: cartQuantity.value,
    );
  }

  Future<void> incrementQuantity() async {
    final cart = Get.find<CartController>();
    final item = cart.cartItems.firstWhereOrNull(
      (i) => i.variantId == product.variantId,
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
    final item = cart.cartItems.firstWhereOrNull(
      (i) => i.variantId == product.variantId,
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
}