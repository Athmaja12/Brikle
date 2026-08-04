// lib/Calculation/Controller/waterproofing_calculator_provider.dart

import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Calculation/Model/waterproofCalculation_model.dart';
import 'package:brikle/Product/Model/productdetails_model.dart';
import 'package:flutter/material.dart';

enum WaterproofingType { terrace, bathroom, tank, wall, liquidWaterproofing }

enum WaterproofingLoadState { idle, ready, calculating, error }

class WaterproofingCalculatorProvider extends ChangeNotifier {
  WaterproofingLoadState state = WaterproofingLoadState.ready;
  WaterproofingCalculatorResponse? calculationResult;
  String errorMessage = '';

  // ─── Current Type ──────────────────────────────────────────────────────
  WaterproofingType currentType = WaterproofingType.terrace;

  // ─── Terrace Controllers ──────────────────────────────────────────────
  final TextEditingController terraceLengthCtrl = TextEditingController(
    text: '30',
  );
  final TextEditingController terraceWidthCtrl = TextEditingController(
    text: '20',
  );
  final TextEditingController terraceCoatsCtrl = TextEditingController(
    text: '2',
  );

  // ─── Bathroom Controllers ─────────────────────────────────────────────
  final TextEditingController bathroomFloorLengthCtrl = TextEditingController(
    text: '6',
  );
  final TextEditingController bathroomFloorWidthCtrl = TextEditingController(
    text: '4',
  );
  final TextEditingController bathroomWallHeightCtrl = TextEditingController(
    text: '3',
  );

  // ─── Tank Controllers ─────────────────────────────────────────────────
  final TextEditingController tankLengthCtrl = TextEditingController(text: '6');
  final TextEditingController tankWidthCtrl = TextEditingController(text: '4');
  final TextEditingController tankHeightCtrl = TextEditingController(text: '4');
  final TextEditingController tankWallsCtrl = TextEditingController(text: '3');

  // ─── Wall Controllers ─────────────────────────────────────────────────
  final TextEditingController wallLengthCtrl = TextEditingController(
    text: '40',
  );
  final TextEditingController wallHeightCtrl = TextEditingController(
    text: '10',
  );
  final TextEditingController wallCoatsCtrl = TextEditingController(text: '2');

  // ─── Liquid Waterproofing Controllers ────────────────────────────────
  final TextEditingController cementBagsCtrl = TextEditingController(
    text: '150',
  );

  // ─── Product Images ──────────────────────────────────────────────────
  final Map<int, String?> _productImages = {};
  bool _loadingImages = false;

  // ─── Track adding to cart ─────────────────────────────────────────────
  final Set<int> addingToCartVariantIds = {};

  // ─── Getters ───────────────────────────────────────────────────────────

  String get currentTitle {
    switch (currentType) {
      case WaterproofingType.terrace:
        return 'Terrace Waterproofing';
      case WaterproofingType.bathroom:
        return 'Bathroom Waterproofing';
      case WaterproofingType.tank:
        return 'Tank Waterproofing';
      case WaterproofingType.wall:
        return 'Wall Waterproofing';
      case WaterproofingType.liquidWaterproofing:
        return 'Liquid Waterproofing';
    }
  }

  bool get showTerraceFields => currentType == WaterproofingType.terrace;
  bool get showBathroomFields => currentType == WaterproofingType.bathroom;
  bool get showTankFields => currentType == WaterproofingType.tank;
  bool get showWallFields => currentType == WaterproofingType.wall;
  bool get showLiquidWaterproofingFields =>
      currentType == WaterproofingType.liquidWaterproofing;

  bool get hasCalculation => calculationResult != null;
  bool get isLoadingImages => _loadingImages;

  String? getProductImage(int materialId) {
    return _productImages[materialId];
  }

  // ─── Type Switching ────────────────────────────────────────────────────

  void switchTo(WaterproofingType type) {
    if (currentType == type) return;
    currentType = type;
    calculationResult = null;
    errorMessage = '';
    _productImages.clear();
    state = WaterproofingLoadState.ready;
    notifyListeners();
  }

  // ─── Calculate ────────────────────────────────────────────────────────

  Future<void> calculate() async {
    state = WaterproofingLoadState.calculating;
    notifyListeners();

    try {
      switch (currentType) {
        case WaterproofingType.terrace:
          await _calculateTerrace();
          break;
        case WaterproofingType.bathroom:
          await _calculateBathroom();
          break;
        case WaterproofingType.tank:
          await _calculateTank();
          break;
        case WaterproofingType.wall:
          await _calculateWall();
          break;
        case WaterproofingType.liquidWaterproofing:
          await _calculateLiquidWaterproofing();
          break;
      }
      state = WaterproofingLoadState.ready;

      // 🔎 DEBUG — confirm related_products actually parsed
      final related = calculationResult?.relatedProducts;
      debugPrint(
        '[Waterproofing] calculate() success for $currentType. '
        'waterproofing=${related?.waterproofing.length ?? 0}, '
        'admixture=${related?.admixture.length ?? 0}',
      );
      for (final p in related?.waterproofing ?? []) {
        debugPrint(
          '[Waterproofing]   product -> materialId=${p.materialId}, '
          'variantId=${p.variantId}, name="${p.name}", '
          'pricePerBucket=${p.pricePerBucket}, pricePerLitre=${p.pricePerLitre}',
        );
      }
      notifyListeners();

      // Load product images after calculation
      await _loadProductImages();
    } catch (e) {
      errorMessage = e.toString();
      state = WaterproofingLoadState.error;
      debugPrint('[Waterproofing] calculate() FAILED: $e');
      notifyListeners();
    }
  }

  // ─── Load Product Images ──────────────────────────────────────────────

  Future<void> _loadProductImages() async {
    if (calculationResult == null) return;

    final products = _getAllProducts();
    debugPrint(
      '[Waterproofing] _loadProductImages: ${products.length} item(s) to fetch',
    );
    if (products.isEmpty) return;

    _loadingImages = true;
    notifyListeners();

    for (final product in products) {
      if (!_productImages.containsKey(product.materialId)) {
        try {
          debugPrint(
            '[Waterproofing]   fetching material detail for materialId=${product.materialId} (${product.name})',
          );
          final json = await ApiService.getMaterialDetails(product.materialId);
          // ⚠️ FIX — was reading json['master_image'] directly, which is a
          // relative path and doesn't render. MaterialDetail.fromJson runs
          // it through _fullImageUrl() to prepend the base URL, same as
          // the block and steel calculators do.
          final detail = MaterialDetail.fromJson(json);
          _productImages[product.materialId] = detail.masterImage;
          debugPrint(
            '[Waterproofing]   -> resolved image for materialId=${product.materialId}: '
            '"${detail.masterImage}"',
          );
          if (detail.masterImage.isEmpty) {
            debugPrint(
              '[Waterproofing]   ⚠️ empty master_image for materialId=${product.materialId}',
            );
          }
        } catch (e) {
          _productImages[product.materialId] = null;
          debugPrint(
            '[Waterproofing]   ⚠️ FAILED to fetch material ${product.materialId}: $e',
          );
        }
      }
    }

    _loadingImages = false;
    notifyListeners();
  }

  List<WaterproofingProduct> _getAllProducts() {
    if (calculationResult == null) return [];
    final related = calculationResult!.relatedProducts;
    return [...related.waterproofing, ...related.admixture];
  }

  // ─── Calculate Methods ────────────────────────────────────────────────

  Future<void> _calculateTerrace() async {
    final length = double.tryParse(terraceLengthCtrl.text);
    final width = double.tryParse(terraceWidthCtrl.text);
    final coats = int.tryParse(terraceCoatsCtrl.text);

    if (length == null || length <= 0) {
      throw Exception('Please enter a valid terrace length');
    }
    if (width == null || width <= 0) {
      throw Exception('Please enter a valid terrace width');
    }
    if (coats == null || coats <= 0) {
      throw Exception('Please enter a valid number of coats');
    }

    final result = await ApiService.calculateTerraceWaterproofing(
      terraceLengthFt: length,
      terraceWidthFt: width,
      coatsApplied: coats,
    );
    calculationResult = result;
  }

  Future<void> _calculateBathroom() async {
    final floorLength = double.tryParse(bathroomFloorLengthCtrl.text);
    final floorWidth = double.tryParse(bathroomFloorWidthCtrl.text);
    final wallHeight = double.tryParse(bathroomWallHeightCtrl.text);

    if (floorLength == null || floorLength <= 0) {
      throw Exception('Please enter a valid floor length');
    }
    if (floorWidth == null || floorWidth <= 0) {
      throw Exception('Please enter a valid floor width');
    }
    if (wallHeight == null || wallHeight <= 0) {
      throw Exception('Please enter a valid wall height');
    }

    final result = await ApiService.calculateBathroomWaterproofing(
      floorLengthFt: floorLength,
      floorWidthFt: floorWidth,
      wallHeightToCoatFt: wallHeight,
    );
    calculationResult = result;
  }

  Future<void> _calculateTank() async {
    final length = double.tryParse(tankLengthCtrl.text);
    final width = double.tryParse(tankWidthCtrl.text);
    final height = double.tryParse(tankHeightCtrl.text);
    final walls = int.tryParse(tankWallsCtrl.text);

    if (length == null || length <= 0) {
      throw Exception('Please enter a valid tank length');
    }
    if (width == null || width <= 0) {
      throw Exception('Please enter a valid tank width');
    }
    if (height == null || height <= 0) {
      throw Exception('Please enter a valid tank height');
    }
    if (walls == null || walls <= 0) {
      throw Exception('Please enter a valid number of walls');
    }

    final result = await ApiService.calculateTankWaterproofing(
      tankLengthFt: length,
      tankWidthFt: width,
      tankHeightFt: height,
      numberOfWalls: walls,
    );
    calculationResult = result;
  }

  Future<void> _calculateWall() async {
    final length = double.tryParse(wallLengthCtrl.text);
    final height = double.tryParse(wallHeightCtrl.text);
    final coats = int.tryParse(wallCoatsCtrl.text);

    if (length == null || length <= 0) {
      throw Exception('Please enter a valid wall length');
    }
    if (height == null || height <= 0) {
      throw Exception('Please enter a valid wall height');
    }
    if (coats == null || coats <= 0) {
      throw Exception('Please enter a valid number of coats');
    }

    final result = await ApiService.calculateWallWaterproofing(
      wallLengthFt: length,
      wallHeightFt: height,
      coatsApplied: coats,
    );
    calculationResult = result;
  }

  Future<void> _calculateLiquidWaterproofing() async {
    final cementBags = int.tryParse(cementBagsCtrl.text);

    if (cementBags == null || cementBags <= 0) {
      throw Exception('Please enter a valid number of cement bags');
    }

    final result = await ApiService.calculateLiquidWaterproofing(
      numberOfCementBags: cementBags,
    );
    calculationResult = result;
  }

  // ─── Cart Methods ──────────────────────────────────────────────────────

  Future<bool> addVariantToCart(int variantId, {int quantity = 1}) async {
    addingToCartVariantIds.add(variantId);
    notifyListeners();
    try {
      await ApiService.addToCart(variantId: variantId, quantity: quantity);
      addingToCartVariantIds.remove(variantId);
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      addingToCartVariantIds.remove(variantId);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    terraceLengthCtrl.dispose();
    terraceWidthCtrl.dispose();
    terraceCoatsCtrl.dispose();
    bathroomFloorLengthCtrl.dispose();
    bathroomFloorWidthCtrl.dispose();
    bathroomWallHeightCtrl.dispose();
    tankLengthCtrl.dispose();
    tankWidthCtrl.dispose();
    tankHeightCtrl.dispose();
    tankWallsCtrl.dispose();
    wallLengthCtrl.dispose();
    wallHeightCtrl.dispose();
    wallCoatsCtrl.dispose();
    cementBagsCtrl.dispose();
    super.dispose();
  }
}
