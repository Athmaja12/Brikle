import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/ApiConfiguration/auth_gate.dart';
import 'package:brikle/Category/Model/category_model.dart';
import 'package:brikle/Category/View/categorydetail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryController extends GetxController {
  // ---------------------------------------------------------------------------
  // STATE
  // ---------------------------------------------------------------------------

  final RxList<CategoryGridItem> categories =
      <CategoryGridItem>[].obs;

  final RxBool isLoading = true.obs;

  // ---------------------------------------------------------------------------
  // DELIVERY / PINCODE
  // ---------------------------------------------------------------------------

  final RxString deliverToPincode = '—'.obs;

  final RxBool isPincodeServiceable = true.obs;

  final RxString pincodeMessage = ''.obs;

  final RxBool isCheckingPincode = false.obs;

  // ---------------------------------------------------------------------------
  // OFFER BANNER
  // ---------------------------------------------------------------------------

  final OfferBanner offerBanner = const OfferBanner(
    title: 'Build Stronger, Build Better',
    subtitle: 'Premium Cement for every Project',
    discountText: 'Upto 50% off',
  );

  // ---------------------------------------------------------------------------
  // PROMO TILES
  // ---------------------------------------------------------------------------

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
      semanticLabel:
          'Protection from rain, moisture & leaks.',
    ),
    CategoryPromoTile(
      assetPath: 'assets/images/cement1.png',
      categoryName: 'cement',
      semanticLabel:
          'Top quality cements for strong structures.',
    ),
    CategoryPromoTile(
      assetPath: 'assets/images/brush.png',
      categoryName: 'brush',
      semanticLabel:
          'Tools for perfect application.',
    ),
  ];

  // ---------------------------------------------------------------------------
  // LIFECYCLE
  // ---------------------------------------------------------------------------

  @override
  void onInit() {
    super.onInit();

    debugPrint(
      '[CategoryController] onInit',
    );

    refresh();
  }

  // ---------------------------------------------------------------------------
  // LOAD CATEGORIES
  // ---------------------------------------------------------------------------

  Future<void> refresh() async {
    isLoading.value = true;

    debugPrint(
      '[CategoryController] refresh() started',
    );

    try {
      // -----------------------------------------------------------------------
      // CATEGORIES ARE PUBLIC
      //
      // Guest users must be able to browse categories.
      //
      // Do NOT call getProfile() together with this request.
      // -----------------------------------------------------------------------

      final results = await ApiService.getCategories();

      categories.value = results
          .map(
            (e) => CategoryGridItem.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList();

      debugPrint(
        '[CategoryController] ✅ getCategories OK — '
        '${categories.length} categories',
      );

      debugPrint(
        '[CategoryController] categories => '
        '${categories.map((c) => '${c.id}:${c.name}').toList()}',
      );

      // -----------------------------------------------------------------------
      // PROFILE IS AUTHENTICATED ONLY
      //
      // Guest users skip profile completely.
      // -----------------------------------------------------------------------

      await _fetchProfileIfLoggedIn();
    } on ApiException catch (e) {
      debugPrint(
        '[CategoryController] ❌ getCategories FAILED: ${e.message}',
      );

      // Do not crash the app.
      categories.clear();

      // This is useful while debugging the backend endpoint.
      if (e.message.contains(
        'Authentication credentials were not provided',
      )) {
        debugPrint(
          '[CategoryController] ⚠️ Categories endpoint is still '
          'requiring authentication.',
        );

        debugPrint(
          '[CategoryController] ⚠️ Guest users need '
          '/api/superadmin/categories/ to be public.',
        );
      }

      // You can keep the snackbar, but I recommend avoiding it for
      // authentication errors during guest browsing.
      if (await AuthGate.isLoggedIn()) {
        Get.snackbar(
          'Could not load Categories',
          e.message,
        );
      }
    } catch (e, stack) {
      debugPrint(
        '[CategoryController] ❌ unexpected error: $e',
      );

      debugPrint(
        '[CategoryController] stack: $stack',
      );
    } finally {
      isLoading.value = false;

      debugPrint(
        '[CategoryController] refresh() finished',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD PROFILE ONLY WHEN LOGGED IN
  // ---------------------------------------------------------------------------

  Future<void> _fetchProfileIfLoggedIn() async {
    final loggedIn = await AuthGate.isLoggedIn();

    debugPrint(
      '[CategoryController] session => '
      '${loggedIn ? "LOGGED IN" : "GUEST"}',
    );

    if (!loggedIn) {
      debugPrint(
        '[CategoryController] Guest user -> '
        'skipping getProfile',
      );

      return;
    }

    try {
      final profile = await ApiService.getProfile();

      debugPrint(
        '[CategoryController] ✅ getProfile OK',
      );

      deliverToPincode.value =
          profile['pincode']?.toString() ?? '—';

      if (deliverToPincode.value != '—') {
        await checkPincode(
          deliverToPincode.value,
        );
      }
    } on ApiException catch (e) {
      debugPrint(
        '[CategoryController] getProfile failed: ${e.message}',
      );

      // Non-fatal.
      // Category list should still remain visible.
    } catch (e, stack) {
      debugPrint(
        '[CategoryController] getProfile unexpected error: $e',
      );

      debugPrint(
        '[CategoryController] stack: $stack',
      );
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
      final response = await ApiService.checkPincode(
        pincode.trim(),
      );

      isPincodeServiceable.value =
          response['is_serviceable'] as bool? ?? false;

      pincodeMessage.value =
          response['message']?.toString() ?? '';

      if (isPincodeServiceable.value) {
        deliverToPincode.value =
            response['pincode']?.toString() ?? pincode;
      }
    } on ApiException catch (e) {
      debugPrint(
        '[CategoryController] checkPincode FAILED: ${e.message}',
      );

      isPincodeServiceable.value = false;

      pincodeMessage.value = e.message;
    } catch (e) {
      debugPrint(
        '[CategoryController] checkPincode unexpected error: $e',
      );

      isPincodeServiceable.value = false;

      pincodeMessage.value =
          'Could not check delivery for this pincode.';
    } finally {
      isCheckingPincode.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // OPEN CATEGORY
  // ---------------------------------------------------------------------------

  void openCategory(
    BuildContext context,
    CategoryGridItem category,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryProductsScreenWrapper(
          categoryId: category.id,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // OPEN CATEGORY BY NAME
  // ---------------------------------------------------------------------------

  void openCategoryByName(
    BuildContext context,
    String categoryName,
  ) {
    final match = categories.firstWhereOrNull(
      (c) =>
          c.name.trim().toLowerCase() ==
          categoryName.trim().toLowerCase(),
    );

    if (match == null) {
      Get.snackbar(
        'Category not found',
        categoryName,
      );

      return;
    }

    openCategory(
      context,
      match,
    );
  }
}