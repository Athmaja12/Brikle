import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Category/View/categorydetail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryProductsController extends GetxController {
  final int categoryId;
  CategoryProductsController({required this.categoryId});

  final RxBool isLoading = true.obs;
  final Rx<CategoryDetail?> category = Rx<CategoryDetail?>(null);
  final Rx<CategoryFilterOptions?> filterOptions = Rx<CategoryFilterOptions?>(
    null,
  );

  // Selected filters — instant-apply, Flipkart/Amazon style (no "Apply" button).
  final RxnInt selectedBrandId = RxnInt();
  final RxString selectedType = ''.obs;
  final RxString selectedQuantity = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        ApiService.getCategoryDetails(categoryId),
        ApiService.getCategoryFilterOptions(categoryId),
      ]);
      category.value = CategoryDetail.fromJson(results[0]);
      filterOptions.value = CategoryFilterOptions.fromJson(results[1]);
    } on ApiException catch (e) {
      debugPrint('[CategoryProductsController] failed: ${e.message}');
      Get.snackbar('Could not load category', e.message);
    } catch (e) {
      debugPrint('[CategoryProductsController] unexpected error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Client-side filtering against the already-fetched product list —
  /// instant results as filters change, matching Flipkart/Amazon's
  /// immediate-apply UX. Switch to server-side query params here later
  /// if the backend adds filtering support to the details endpoint.
  List<CategoryProductItem> get filteredProducts {
    final all = category.value?.products ?? [];
    return all.where((p) {
      if (selectedBrandId.value != null && p.brandId != selectedBrandId.value)
        return false;
      if (selectedType.value.isNotEmpty && p.type != selectedType.value)
        return false;
      if (selectedQuantity.value.isNotEmpty &&
          p.quantity != selectedQuantity.value)
        return false;
      return true;
    }).toList();
  }

  void setBrandFilter(int? brandId) => selectedBrandId.value = brandId;
  void setTypeFilter(String type) =>
      selectedType.value = selectedType.value == type ? '' : type;
  void setQuantityFilter(String qty) =>
      selectedQuantity.value = selectedQuantity.value == qty ? '' : qty;

  void clearFilters() {
    selectedBrandId.value = null;
    selectedType.value = '';
    selectedQuantity.value = '';
  }

  /// Switching category from the filter dropdown reloads this same screen
  /// with the new category_id — simplest option, same architecture as
  /// tapping a category card from the grid.
  void switchCategory(BuildContext context, int newCategoryId) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CategoryProductsScreenWrapper(categoryId: newCategoryId),
      ),
    );
  }
}
