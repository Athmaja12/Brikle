import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/ApiConfiguration/auth_gate.dart';
import 'package:brikle/HomePage/Model/home_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxList<CarouselItem> carousels = <CarouselItem>[].obs;
  final RxList<CategoryItem> categories = <CategoryItem>[].obs;
  final RxInt selectedCategoryIndex = (-1).obs;
  final RxBool isLoading = true.obs;

  final GlobalKey categoriesSectionKey = GlobalKey();
  final RxString deliverToPincode = '—'.obs;
  final RxString customerName = ''.obs;

  final RxList<DealItem> topDeals = <DealItem>[].obs;

  final RxList<BestSellingItem> bestselling = <BestSellingItem>[].obs;
  final RxBool isBestsellingLoading = false.obs;
  final RxString bestsellingCategoryName = ''.obs;

  final Map<String, ({String title, String subtitle, String imageUrl})>
  categoryBanner = const {
    'Cements': (
      title: 'Build Stronger, Build Better',
      subtitle: 'Premium Cement for every Project',
      imageUrl: '',
    ),
  };

  final List<PromoTile> promoTiles = const [
    PromoTile(
      assetPath: 'assets/images/putty.png',
      categoryName: 'Electricals',
      semanticLabel:
          'Putty & Primers from top brands. Get guaranteed lowest prices.',
    ),
    PromoTile(
      assetPath: 'assets/images/paint.png',
      categoryName: 'paint',
      semanticLabel:
          'Protection from rain, moisture & leaks. Get Dr. Fixit & Asian waterproofing products.',
    ),
    PromoTile(
      assetPath: 'assets/images/cement1.png',
      categoryName: 'cement',
      semanticLabel: 'Top quality cements for strong structures.',
    ),
    PromoTile(
      assetPath: 'assets/images/brush.png',
      categoryName: 'brush',
      semanticLabel: 'Tools for perfect application.',
    ),
  ];

  void goToCategory(String categoryName) {
    debugPrint('[HomeController] goToCategory("$categoryName") called');
    debugPrint(
      '[HomeController] available categories: ${categories.map((c) => "${c.id}:${c.name}").toList()}',
    );

    final index = categories.indexWhere(
      (c) => c.name.trim().toLowerCase() == categoryName.trim().toLowerCase(),
    );

    debugPrint('[HomeController] matched index: $index');

    if (index == -1) {
      debugPrint(
        '[HomeController] goToCategory: NO MATCH for "$categoryName" — check promoTiles.categoryName vs actual category names above',
      );
      Get.snackbar('Category not found', categoryName);
      return;
    }

    onCategoryTap(index);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = categoriesSectionKey.currentContext;
      debugPrint(
        '[HomeController] categoriesSectionKey.currentContext is ${ctx == null ? "NULL (key not attached in HomeScreen?)" : "attached"}',
      );
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.05,
        );
      }
    });
  }

  String get selectedCategoryName =>
      categories.isNotEmpty &&
          selectedCategoryIndex.value >= 0 &&
          selectedCategoryIndex.value < categories.length
      ? categories[selectedCategoryIndex.value].name
      : '';

  ({String title, String subtitle, String imageUrl}) get currentBanner =>
      categoryBanner[selectedCategoryName] ?? categoryBanner.values.first;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[HomeController] onInit — calling refresh()');
    refresh();
  }

  Future<void> refresh() async {
    isLoading.value = true;
    debugPrint('[HomeController] refresh() started');

    try {
      debugPrint(
        '[HomeController] Loading public APIs in parallel: '
        'carousel, categories, deals',
      );

      // -----------------------------------------------------------------------
      // CAROUSEL + CATEGORIES + DEALS — independent of each other, so run
      // them concurrently instead of one after another. This is the main
      // fix for the Home page load lag.
      // -----------------------------------------------------------------------
      await Future.wait([_loadCarousel(), _loadCategories(), _loadDeals()]);

      // -----------------------------------------------------------------------
      // PROFILE + BEST SELLING
      // -----------------------------------------------------------------------
      // Profile is authenticated only. Bestselling depends on categories
      // being loaded above. Both are indepe ndent of each other, so run
      // them together as well.
      // -----------------------------------------------------------------------
      final int? bestsellingCategoryId = categories.isNotEmpty
          ? categories[selectedCategoryIndex.value >= 0 &&
                        selectedCategoryIndex.value < categories.length
                    ? selectedCategoryIndex.value
                    : 0]
                .id
          : null;
      // NOTE: selectedCategoryIndex is intentionally left at -1 here.
      // It now ONLY drives the tile highlight in _CategoriesSection.
      // bestsellingCategoryId above still defaults to categories[0]'s id
      // so the initial Bestselling load/title behaves exactly as before —
      // just without visually marking any tile as selected.

      await Future.wait([
        _fetchProfileIfLoggedIn(),
        if (bestsellingCategoryId != null)
          _loadBestselling(bestsellingCategoryId)
        else
          _clearBestselling(),
      ]);
    } catch (e, stack) {
      // This should almost never be reached because each API above
      // handles its own exception.
      debugPrint('[HomeController] ❌ refresh() unexpected error: $e');
      debugPrint('[HomeController] stack: $stack');
    } finally {
      isLoading.value = false;
      debugPrint('[HomeController] refresh() finished — isLoading=false');
    }
  }

  Future<void> _loadCarousel() async {
    try {
      final carouselResponse = await ApiService.getCarousel();

      carousels.value = carouselResponse
          .map((e) => CarouselItem.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint(
        '[HomeController] ✅ getCarousel OK — '
        '${carousels.length} items',
      );
    } on ApiException catch (e) {
      debugPrint('[HomeController] ❌ getCarousel FAILED: ${e.message}');
      carousels.clear();
    } catch (e) {
      debugPrint('[HomeController] ❌ getCarousel unexpected error: $e');
      carousels.clear();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categoryResponse = await ApiService.getCategories();

      categories.value = categoryResponse
          .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint(
        '[HomeController] ✅ getCategories OK — '
        '${categories.length} items',
      );

      debugPrint(
        '[HomeController] parsed categories: '
        '${categories.map((c) => '${c.id}:${c.name}').toList()}',
      );
    } on ApiException catch (e) {
      debugPrint('[HomeController] ❌ getCategories FAILED: ${e.message}');
      categories.clear();
    } catch (e) {
      debugPrint('[HomeController] ❌ getCategories unexpected error: $e');
      categories.clear();
    }
  }

  Future<void> _loadDeals() async {
    try {
      final dealsResponse = await ApiService.getDealsOfWeek();

      topDeals.value = dealsResponse
          .map((e) => DealItem.fromJson(e as Map<String, dynamic>))
          .toList();

      debugPrint(
        '[HomeController] ✅ getDealsOfWeek OK — '
        '${topDeals.length} items',
      );
    } on ApiException catch (e) {
      debugPrint('[HomeController] ❌ getDealsOfWeek FAILED: ${e.message}');
      topDeals.clear();
    } catch (e) {
      debugPrint('[HomeController] ❌ getDealsOfWeek unexpected error: $e');
      topDeals.clear();
    }
  }

  /// Wrapped as a Future so it can sit alongside other awaited calls in
  /// Future.wait([...]) — clear() itself returns void and can't be used
  /// as a list element directly.
  Future<void> _clearBestselling() async {
    debugPrint(
      '[HomeController] Categories unavailable — '
      'skipping bestselling load',
    );
    bestselling.clear();
    bestsellingCategoryName.value = '';
  }

  /// Profile is only fetched for logged-in users. For guests this is a
  /// silent no-op — deliverToPincode/customerName simply stay at their
  /// defaults, and no pincode-serviceability check runs since there's
  /// no saved pincode to check yet.
  Future<void> _fetchProfileIfLoggedIn() async {
    if (!await AuthGate.isLoggedIn()) {
      debugPrint('[HomeController] skipping getProfile — guest session');
      return;
    }

    try {
      final profile = await ApiService.getProfile();
      debugPrint('[HomeController] ✅ getProfile OK — $profile');

      deliverToPincode.value = profile['pincode']?.toString() ?? '—';
      customerName.value = profile['full_name']?.toString() ?? '';

      if (deliverToPincode.value != '—') {
        checkPincode(deliverToPincode.value);
      }
    } on ApiException catch (e) {
      debugPrint('[HomeController] ❌ getProfile FAILED: ${e.message}');
      // Non-fatal — logged-in profile fetch failing (expired token mid-
      // session, etc.) shouldn't block the rest of Home from rendering.
    } catch (e, stack) {
      debugPrint('[HomeController] ❌ getProfile unexpected error: $e');
      debugPrint('[HomeController] stack: $stack');
    }
  }

  Future<void> _loadBestselling(int categoryId) async {
    isBestsellingLoading.value = true;
    debugPrint(
      '[HomeController] _loadBestselling(categoryId: $categoryId) started',
    );

    // Resolve the display name for whichever category we're loading —
    // independent of selectedCategoryIndex, so the "Bestselling on X"
    // title works whether or not a tile is actually highlighted.
    CategoryItem? matched;
    for (final c in categories) {
      if (c.id == categoryId) {
        matched = c;
        break;
      }
    }
    bestsellingCategoryName.value = matched?.name ?? '';

    try {
      final results = await ApiService.getBestSelling(categoryId);
      debugPrint(
        '[HomeController] ✅ getBestSelling OK — ${results.length} items for categoryId=$categoryId',
      );
      debugPrint(results.toString());
      bestselling.value = results
          .map((e) => BestSellingItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException catch (e) {
      debugPrint(
        '[HomeController] ❌ getBestSelling FAILED for categoryId=$categoryId: ${e.message}',
      );
      debugPrint('[HomeController] full exception object: $e');
      bestselling.clear();
    } catch (e, stack) {
      debugPrint('[HomeController] ❌ getBestSelling unexpected error: $e');
      debugPrint('[HomeController] stack: $stack');
      bestselling.clear();
    } finally {
      isBestsellingLoading.value = false;
    }
  }

  void onCategoryTap(int index) {
    debugPrint('[HomeController] onCategoryTap(index: $index)');
    selectedCategoryIndex.value = index;
    if (index < categories.length) {
      debugPrint(
        '[HomeController] selected category → id=${categories[index].id}, name=${categories[index].name}',
      );
      _loadBestselling(categories[index].id);
    } else {
      debugPrint(
        '[HomeController] onCategoryTap: index $index out of range (categories.length=${categories.length})',
      );
    }
  }

  void resetAfterCategoryVisit() {
    selectedCategoryIndex.value = -1;
    bestselling.clear();
    bestsellingCategoryName.value = '';
  }

  // ── Pincode serviceability ────────────────────────────────────────────
  final RxBool isPincodeServiceable = true.obs;
  final RxString pincodeMessage = ''.obs;
  final RxBool isCheckingPincode = false.obs;

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
      debugPrint('[HomeController] checkPincode FAILED: ${e.message}');
      isPincodeServiceable.value = false;
      pincodeMessage.value = e.message;
    } catch (e) {
      debugPrint('[HomeController] checkPincode unexpected error: $e');
      isPincodeServiceable.value = false;
      pincodeMessage.value = 'Could not check delivery for this pincode.';
    } finally {
      isCheckingPincode.value = false;
    }
  }

  Future<void> refreshLoggedInProfile() async {
    debugPrint('[HomeController] refreshLoggedInProfile() called');

    if (!await AuthGate.isLoggedIn()) {
      debugPrint(
        '[HomeController] refreshLoggedInProfile() skipped — '
        'user is not logged in',
      );
      return;
    }

    await _fetchProfileIfLoggedIn();

    debugPrint(
      '[HomeController] logged-in profile refreshed — '
      'pincode: ${deliverToPincode.value}',
    );
  }
}
