import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/HomePage/Model/home_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final RxList<CarouselItem> carousels = <CarouselItem>[].obs;
  final RxList<CategoryItem> categories = <CategoryItem>[].obs;
  final RxInt selectedCategoryIndex = 0.obs;
  final RxBool isLoading = true.obs;

  final GlobalKey categoriesSectionKey = GlobalKey();
  final RxString deliverToPincode = '—'.obs;
  final RxString customerName = ''.obs;

  final RxList<DealItem> topDeals = <DealItem>[].obs;

  final RxList<BestSellingItem> bestselling = <BestSellingItem>[].obs;
  final RxBool isBestsellingLoading = false.obs;

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
      categories.isNotEmpty && selectedCategoryIndex.value < categories.length
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
        '[HomeController] → calling getCarousel, getCategories, getProfile, getDealsOfWeek',
      );

      final results = await Future.wait([
        ApiService.getCarousel()
            .then((r) {
              debugPrint(
                '[HomeController] ✅ getCarousel OK — ${(r as List).length} items',
              );
              return r;
            })
            .catchError((e) {
              debugPrint('[HomeController] ❌ getCarousel FAILED: $e');
              throw e;
            }),
        ApiService.getCategories()
            .then((r) {
              debugPrint(
                '[HomeController] ✅ getCategories OK — ${(r as List).length} items',
              );
              return r;
            })
            .catchError((e) {
              debugPrint('[HomeController] ❌ getCategories FAILED: $e');
              throw e;
            }),
        ApiService.getProfile()
            .then((r) {
              debugPrint('[HomeController] ✅ getProfile OK — $r');
              return r;
            })
            .catchError((e) {
              debugPrint('[HomeController] ❌ getProfile FAILED: $e');
              throw e;
            }),
        ApiService.getDealsOfWeek()
            .then((r) {
              debugPrint(
                '[HomeController] ✅ getDealsOfWeek OK — ${(r as List).length} items',
              );
              return r;
            })
            .catchError((e) {
              debugPrint('[HomeController] ❌ getDealsOfWeek FAILED: $e');
              throw e;
            }),
      ]);

      carousels.value = (results[0] as List)
          .map((e) => CarouselItem.fromJson(e as Map<String, dynamic>))
          .toList();

      categories.value = (results[1] as List)
          .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
          .toList();
      debugPrint(
        '[HomeController] parsed categories: ${categories.map((c) => "${c.id}:${c.name}").toList()}',
      );

      final profile = results[2] as Map<String, dynamic>;
      deliverToPincode.value = profile['pincode']?.toString() ?? '—';
      customerName.value = profile['full_name']?.toString() ?? '';

      topDeals.value = (results[3] as List)
          .map((e) => DealItem.fromJson(e as Map<String, dynamic>))
          .toList();
      // ← NEW: auto-check serviceability for the profile's pincode
      if (deliverToPincode.value != '—') {
        checkPincode(deliverToPincode.value);
      }

      if (categories.isNotEmpty) {
        debugPrint(
          '[HomeController] loading bestselling for default category id=${categories[selectedCategoryIndex.value].id}',
        );
        await _loadBestselling(categories[selectedCategoryIndex.value].id);
      } else {
        debugPrint(
          '[HomeController] categories list is EMPTY — skipping bestselling load',
        );
      }
    } on ApiException catch (e) {
      debugPrint('[HomeController] ❌ refresh() ApiException: ${e.message}');
      debugPrint('[HomeController] full exception object: $e');
      Get.snackbar('Could not load Home', e.message);
    } catch (e, stack) {
      debugPrint('[HomeController] ❌ refresh() unexpected error: $e');
      debugPrint('[HomeController] stack: $stack');
    } finally {
      isLoading.value = false;
      debugPrint('[HomeController] refresh() finished — isLoading=false');
    }
  }



  Future<void> _loadBestselling(int categoryId) async {
    isBestsellingLoading.value = true;
    debugPrint(
      '[HomeController] _loadBestselling(categoryId: $categoryId) started',
    );

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
}
