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
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final response = await ApiService.getMaterialDetails(product.materialId);
      detail.value = MaterialDetail.fromJson(response);
    } on ApiException catch (e) {
      debugPrint('[ProductDetailController] failed: ${e.message}');
      Get.snackbar('Could not load product', e.message);
    } catch (e) {
      debugPrint('[ProductDetailController] unexpected error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void selectImage(int index) => selectedImageIndex.value = index;
  void toggleWishlist() => isWishlisted.value = !isWishlisted.value;

  void toggleHighlights() =>
      highlightsExpanded.value = !highlightsExpanded.value;
  void toggleDescription() =>
      descriptionExpanded.value = !descriptionExpanded.value;
  void toggleFaqs() => faqsExpanded.value = !faqsExpanded.value;
  void toggleReturns() => returnsExpanded.value = !returnsExpanded.value;

  void addToCart() {
    Get.find<CartController>().addToCart(
      variantId: product.variantId,
      quantity: 1,
    );
  }

  void buyNow() {
    // TODO: wire to checkout flow with product.variantId
    Get.snackbar('Buy Now', 'Proceeding with ${product.name}');
  }
}
