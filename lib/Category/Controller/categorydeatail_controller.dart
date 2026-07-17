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

  final RxnInt selectedBrandId = RxnInt();
  final RxString selectedType = ''.obs;
  final RxString selectedQuantity = ''.obs;

  // ── Pincode serviceability ────────────────────────────────────────
  final RxString deliverToPincode = '—'.obs;
  final RxBool isPincodeServiceable = true.obs;
  final RxString pincodeMessage = ''.obs;
  final RxBool isCheckingPincode = false.obs;

  @override
  void onInit() {
    super.onInit();
    refresh();
  }

  /// Public refresh() — used both on init and by pull-to-refresh.
  Future<void> refresh() async {
    isLoading.value = true;
    try {
      final results = await Future.wait([
        ApiService.getCategoryDetails(categoryId),
        ApiService.getCategoryFilterOptions(categoryId),
        ApiService.getProfile(),
      ]);
      category.value = CategoryDetail.fromJson(results[0]);
      filterOptions.value = CategoryFilterOptions.fromJson(results[1]);

      final profile = results[2] as Map<String, dynamic>;
      deliverToPincode.value = profile['pincode']?.toString() ?? '—';
      if (deliverToPincode.value != '—') {
        checkPincode(deliverToPincode.value);
      }
    } on ApiException catch (e) {
      debugPrint('[CategoryProductsController] failed: ${e.message}');
      Get.snackbar('Could not load category', e.message);
    } catch (e) {
      debugPrint('[CategoryProductsController] unexpected error: $e');
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
