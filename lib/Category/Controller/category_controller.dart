import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Category/Model/category_model.dart';
import 'package:brikle/Category/View/categorydetail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryController extends GetxController {
  final RxList<CategoryGridItem> categories = <CategoryGridItem>[].obs;
  final RxBool isLoading = true.obs;

  final RxString deliverToPincode = '—'.obs;

  // ── Pincode serviceability (mirrors HomeController) ──────────────────
  final RxBool isPincodeServiceable = true.obs;
  final RxString pincodeMessage = ''.obs;
  final RxBool isCheckingPincode = false.obs;

  final OfferBanner offerBanner = const OfferBanner(
    title: 'Build Stronger, Build Better',
    subtitle: 'Premium Cement for every Project',
    discountText: 'Upto 50% off',
  );

  final List<CategoryPromoTile> promoTiles = const [
    CategoryPromoTile(
      assetPath: 'assets/images/putty.png',
      categoryName: 'Electricals',
      semanticLabel:
          'Putty & Primers from top brands. Get guaranteed lowest prices.',
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
    refresh();
  }

  /// Renamed from _loadAll → public refresh() so RefreshIndicator (pull
  /// to refresh) and the pincode sheet can both call it, same pattern
  /// as HomeController.refresh().
  Future<void> refresh() async {
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

      if (deliverToPincode.value != '—') {
        checkPincode(deliverToPincode.value);
      }
    } on ApiException catch (e) {
      debugPrint('[CategoryController] failed: ${e.message}');
      Get.snackbar('Could not load Categories', e.message);
    } catch (e) {
      debugPrint('[CategoryController] unexpected error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> checkPincode(String pincode) async {
    isCheckingPincode.value = true;
    try {
      final response = await ApiService.checkPincode(pincode);
      isPincodeServiceable.value = response['is_serviceable'] as bool? ?? false;
      pincodeMessage.value = response['message']?.toString() ?? '';
      if (isPincodeServiceable.value) {
        deliverToPincode.value = response['pincode']?.toString() ?? pincode;
      }
    } on ApiException catch (e) {
      isPincodeServiceable.value = false;
      pincodeMessage.value = e.message;
    } catch (e) {
      isPincodeServiceable.value = false;
      pincodeMessage.value = 'Could not check delivery for this pincode.';
    } finally {
      isCheckingPincode.value = false;
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
