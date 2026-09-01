// lib/Category/Controller/categorydeatail_controller.dart

import 'dart:async';

import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/ApiConfiguration/auth_gate.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Category/View/categorydetail_screen.dart';
import 'package:brikle/HomePage/Controller/home_provider.dart';
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
  final RxString selectedSort = 'default'.obs;

  // ---------------------------------------------------------------------------
  // DELIVERY / PINCODE
  //
  // We mirror HomeController's values by default (no extra network call).
  // Only if HomeController isn't registered / has no pincode yet do we
  // fall back to fetching it ourselves — and even then, it never blocks
  // isLoading.
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
    debugPrint('[CategoryProductsController] onInit categoryId=$categoryId');
    refresh();
  }

  // ---------------------------------------------------------------------------
  // REFRESH — category + filters load in PARALLEL and gate isLoading.
  // Profile/pincode load AFTER, in the background, and never block the UI.
  // ---------------------------------------------------------------------------

  Future<void> refresh() async {
    isLoading.value = true;
    debugPrint(
      '[CategoryProductsController] refresh() started categoryId=$categoryId',
    );

    try {
      // Fire both requests at once instead of one-after-another.
      final results = await Future.wait([
        ApiService.getCategoryDetails(categoryId),
        ApiService.getCategoryFilterOptions(categoryId).catchError((e) {
          // Filters are non-critical — swallow errors here so a filter
          // failure never takes down the whole page.
          debugPrint(
            '[CategoryProductsController] ❌ getCategoryFilterOptions FAILED: $e',
          );
          return <String, dynamic>{};
        }),
      ]);

      category.value = CategoryDetail.fromJson(
        results[0] as Map<String, dynamic>,
      );

      final filterJson = results[1] as Map<String, dynamic>;
      filterOptions.value = filterJson.isEmpty
          ? null
          : CategoryFilterOptions.fromJson(filterJson);

      debugPrint('[CategoryProductsController] ✅ category+filters OK');
    } on ApiException catch (e) {
      debugPrint('[CategoryProductsController] ❌ refresh failed: ${e.message}');
      category.value = null;
      Get.snackbar('Could not load category', e.message);
    } catch (e, stack) {
      debugPrint('[CategoryProductsController] ❌ unexpected error: $e');
      debugPrint('[CategoryProductsController] stack: $stack');
    } finally {
      // UI unblocks here — products are visible now.
      isLoading.value = false;
      debugPrint(
        '[CategoryProductsController] refresh() finished (UI unblocked)',
      );
    }

    // Delivery info is not needed to render products, so it runs
    // unawaited in the background and updates reactively when ready.
    _loadDeliveryInfo();
  }

  // ---------------------------------------------------------------------------
  // DELIVERY INFO — background only, never blocks isLoading
  // ---------------------------------------------------------------------------

  void _loadDeliveryInfo() {
    // Prefer whatever HomeController already resolved at app startup —
    // avoids a redundant getProfile()/checkPincode() round trip on every
    // single category open.
    if (Get.isRegistered<HomeController>()) {
      final home = Get.find<HomeController>();
      final homePincode = home.deliverToPincode.value;

      if (homePincode.isNotEmpty && homePincode != '—') {
        deliverToPincode.value = homePincode;
        isPincodeServiceable.value = home.isPincodeServiceable.value;
        pincodeMessage.value = home.pincodeMessage.value;
        return; // done — no network call needed
      }
    }

    // Fallback: only hit the network if we truly have nothing cached.
    unawaited(_fetchProfileIfLoggedIn());
  }

  Future<void> _fetchProfileIfLoggedIn() async {
    final loggedIn = await AuthGate.isLoggedIn();
    if (!loggedIn) return;

    try {
      final profile = await ApiService.getProfile();
      deliverToPincode.value = profile['pincode']?.toString() ?? '—';

      if (deliverToPincode.value != '—') {
        await checkPincode(deliverToPincode.value);
      }
    } on ApiException catch (e) {
      debugPrint(
        '[CategoryProductsController] getProfile failed: ${e.message}',
      );
    } catch (e) {
      debugPrint(
        '[CategoryProductsController] getProfile unexpected error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // PINCODE
  // ---------------------------------------------------------------------------

  Future<void> checkPincode(String pincode) async {
    if (pincode.trim().isEmpty) return;

    isCheckingPincode.value = true;
    try {
      final response = await ApiService.checkPincode(pincode.trim());
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

  // ---------------------------------------------------------------------------
  // FILTERED PRODUCTS / FILTER ACTIONS / SWITCH CATEGORY — unchanged
  // ---------------------------------------------------------------------------

  List<CategoryProductItem> get filteredProducts {
    final all = category.value?.products ?? [];
    var filtered = all.where((p) {
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

    switch (selectedSort.value) {
      case 'price_low_to_high':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high_to_low':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        break;
    }
    return filtered;
  }

  void setBrandFilter(int? brandId) => selectedBrandId.value = brandId;
  void setTypeFilter(String type) =>
      selectedType.value = selectedType.value == type ? '' : type;
  void setQuantityFilter(String qty) =>
      selectedQuantity.value = selectedQuantity.value == qty ? '' : qty;
  void setSort(String sortOption) => selectedSort.value = sortOption;

  void clearFilters() {
    selectedBrandId.value = null;
    selectedType.value = '';
    selectedQuantity.value = '';
    selectedSort.value = 'default';
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
