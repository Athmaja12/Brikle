import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Category/Model/category_model.dart';
import 'package:brikle/Category/View/categorydetail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryController extends GetxController {
  final RxList<CategoryGridItem> categories = <CategoryGridItem>[].obs;
  final RxBool isLoading = true.obs;

  final RxString deliverToPincode = '—'.obs; // ← NEW

  final OfferBanner offerBanner = const OfferBanner(
    title: 'Build Stronger, Build Better',
    subtitle: 'Premium Cement for every Project',
    discountText: 'Upto 50% off',
  );

  final List<CategoryPromoTile> promoTiles = const [
    CategoryPromoTile(
      assetPath: 'assets/images/putty.png',
      categoryName: 'Electricals',
      semanticLabel: 'Putty & Primers from top brands. Get guaranteed lowest prices.',
    ),
    CategoryPromoTile(
      assetPath: 'assets/images/paint.png',
      categoryName: 'paint',
      semanticLabel: 'Protection from rain, moisture & leaks.',
    ),
    CategoryPromoTile(
      assetPath: 'assets/images/cement1.png',
      categoryName: 'cement',
      semanticLabel: 'Top quality cements for strong structures.',
    ),
    CategoryPromoTile(
      assetPath: 'assets/images/brush.png',
      categoryName: 'brush',
      semanticLabel: 'Tools for perfect application.',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  Future<void> _loadAll() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        ApiService.getCategories(),
        ApiService.getProfile(),
      ]);

      categories.value = (results[0] as List)
          .map((e) => CategoryGridItem.fromJson(e as Map<String, dynamic>))
          .toList();

      final profile = results[1] as Map<String, dynamic>;
      deliverToPincode.value = profile['pincode']?.toString() ?? '—';
    } on ApiException catch (e) {
      debugPrint('[CategoryController] failed: ${e.message}');
      Get.snackbar('Could not load Categories', e.message);
    } catch (e) {
      debugPrint('[CategoryController] unexpected error: $e');
    } finally {
      isLoading.value = false;
    }
  }


void openCategory(BuildContext context, CategoryGridItem category) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CategoryProductsScreenWrapper(categoryId: category.id),
    ),
  );
}

  void openCategoryByName(BuildContext context, String categoryName) {
    final match = categories.firstWhereOrNull(
      (c) => c.name.trim().toLowerCase() == categoryName.trim().toLowerCase(),
    );
    if (match == null) {
      Get.snackbar('Category not found', categoryName);
      return;
    }
    openCategory(context, match);
  }
}