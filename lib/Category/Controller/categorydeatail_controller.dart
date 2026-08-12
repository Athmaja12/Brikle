import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/ApiConfiguration/auth_gate.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Category/View/categorydetail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryProductsController extends GetxController {
  final int categoryId;

  CategoryProductsController({required this.categoryId});

  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  final RxBool isLoading = true.obs;

  final Rx<CategoryDetail?> category = Rx<CategoryDetail?>(null);

  final Rx<CategoryFilterOptions?> filterOptions = Rx<CategoryFilterOptions?>(
    null,
  );

  // ---------------------------------------------------------------------------
  // FILTERS
  // ---------------------------------------------------------------------------

  final RxnInt selectedBrandId = RxnInt();

  final RxString selectedType = ''.obs;

  final RxString selectedQuantity = ''.obs;

  // ---------------------------------------------------------------------------
  // DELIVERY / PINCODE
  // ---------------------------------------------------------------------------

  final RxString deliverToPincode = '—'.obs;

  final RxBool isPincodeServiceable = true.obs;

  final RxString pincodeMessage = ''.obs;

  final RxBool isCheckingPincode = false.obs;

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    debugPrint(
      '[CategoryProductsController] onInit '
      'categoryId=$categoryId',
    );

    refresh();
  }

  // ---------------------------------------------------------------------------
  // REFRESH
  // ---------------------------------------------------------------------------

  Future<void> refresh() async {
    isLoading.value = true;

    debugPrint(
      '[CategoryProductsController] refresh() started '
      'categoryId=$categoryId',
    );

    try {
      // -----------------------------------------------------------------------
      // PUBLIC APIs
      //
      // Guests must be able to:
      //   - open category
      //   - see category products
      //   - see filters
      //
      // Therefore profile is NOT included here.
      // -----------------------------------------------------------------------

      try {
        final categoryResponse = await ApiService.getCategoryDetails(
          categoryId,
        );

        category.value = CategoryDetail.fromJson(categoryResponse);

        debugPrint(
          '[CategoryProductsController] ✅ '
          'getCategoryDetails OK',
        );
      } on ApiException catch (e) {
        debugPrint(
          '[CategoryProductsController] ❌ '
          'getCategoryDetails FAILED: ${e.message}',
        );

        category.value = null;

        rethrow;
      }

      // -----------------------------------------------------------------------
      // FILTER OPTIONS
      // -----------------------------------------------------------------------

      try {
        final filterResponse = await ApiService.getCategoryFilterOptions(
          categoryId,
        );

        filterOptions.value = CategoryFilterOptions.fromJson(filterResponse);

        debugPrint(
          '[CategoryProductsController] ✅ '
          'getCategoryFilterOptions OK',
        );
      } on ApiException catch (e) {
        debugPrint(
          '[CategoryProductsController] ❌ '
          'getCategoryFilterOptions FAILED: ${e.message}',
        );

        // Filter failure should not necessarily destroy the category page.
        filterOptions.value = null;
      } catch (e) {
        debugPrint(
          '[CategoryProductsController] ❌ '
          'getCategoryFilterOptions unexpected error: $e',
        );

        filterOptions.value = null;
      }

      // -----------------------------------------------------------------------
      // PROFILE
      // -----------------------------------------------------------------------
      //
      // Profile is authenticated only.
      //
      // Guest:
      //   Skip it.
      //
      // Logged in:
      //   Fetch pincode and check serviceability.
      // -----------------------------------------------------------------------

      await _fetchProfileIfLoggedIn();
    } on ApiException catch (e) {
      debugPrint('[CategoryProductsController] ❌ refresh failed: ${e.message}');

      Get.snackbar('Could not load category', e.message);
    } catch (e, stack) {
      debugPrint('[CategoryProductsController] ❌ unexpected error: $e');

      debugPrint('[CategoryProductsController] stack: $stack');
    } finally {
      isLoading.value = false;

      debugPrint('[CategoryProductsController] refresh() finished');
    }
  }

  // ---------------------------------------------------------------------------
  // PROFILE — AUTHENTICATED USERS ONLY
  // ---------------------------------------------------------------------------

  Future<void> _fetchProfileIfLoggedIn() async {
    final loggedIn = await AuthGate.isLoggedIn();

    debugPrint(
      '[CategoryProductsController] session => '
      '${loggedIn ? "LOGGED IN" : "GUEST"}',
    );

    if (!loggedIn) {
      debugPrint(
        '[CategoryProductsController] Guest user -> '
        'skipping getProfile',
      );

      return;
    }

    try {
      final profile = await ApiService.getProfile();

      debugPrint('[CategoryProductsController] ✅ getProfile OK');

      deliverToPincode.value = profile['pincode']?.toString() ?? '—';

      if (deliverToPincode.value != '—') {
        await checkPincode(deliverToPincode.value);
      }
    } on ApiException catch (e) {
      debugPrint(
        '[CategoryProductsController] getProfile failed: '
        '${e.message}',
      );

      // Non-fatal.
      // Products remain visible even if profile fails.
    } catch (e, stack) {
      debugPrint(
        '[CategoryProductsController] getProfile unexpected error: $e',
      );

      debugPrint('[CategoryProductsController] stack: $stack');
    }
  }

  // ---------------------------------------------------------------------------
  // PINCODE
  // ---------------------------------------------------------------------------

  Future<void> checkPincode(String pincode) async {
    if (pincode.trim().isEmpty) {
      return;
    }

    isCheckingPincode.value = true;

    try {
      final response = await ApiService.checkPincode(pincode.trim());

      isPincodeServiceable.value = response['is_serviceable'] as bool? ?? false;

      pincodeMessage.value = response['message']?.toString() ?? '';

      if (isPincodeServiceable.value) {
        deliverToPincode.value = response['pincode']?.toString() ?? pincode;
      }
    } on ApiException catch (e) {
      debugPrint(
        '[CategoryProductsController] checkPincode FAILED: '
        '${e.message}',
      );

      isPincodeServiceable.value = false;

      pincodeMessage.value = e.message;
    } catch (e) {
      debugPrint(
        '[CategoryProductsController] checkPincode unexpected error: $e',
      );

      isPincodeServiceable.value = false;

      pincodeMessage.value = 'Could not check delivery for this pincode.';
    } finally {
      isCheckingPincode.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // FILTERED PRODUCTS
  // ---------------------------------------------------------------------------

  List<CategoryProductItem> get filteredProducts {
    final all = category.value?.products ?? [];

    return all.where((p) {
      if (selectedBrandId.value != null && p.brandId != selectedBrandId.value) {
        return false;
      }

      if (selectedType.value.isNotEmpty && p.type != selectedType.value) {
        return false;
      }

      if (selectedQuantity.value.isNotEmpty &&
          p.quantity != selectedQuantity.value) {
        return false;
      }

      return true;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // FILTER ACTIONS
  // ---------------------------------------------------------------------------

  void setBrandFilter(int? brandId) {
    selectedBrandId.value = brandId;
  }

  void setTypeFilter(String type) {
    selectedType.value = selectedType.value == type ? '' : type;
  }

  void setQuantityFilter(String qty) {
    selectedQuantity.value = selectedQuantity.value == qty ? '' : qty;
  }

  void clearFilters() {
    selectedBrandId.value = null;
    selectedType.value = '';
    selectedQuantity.value = '';
  }

  // ---------------------------------------------------------------------------
  // SWITCH CATEGORY
  // ---------------------------------------------------------------------------

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
