// provider/paint_calculator_provider.dart

import 'package:brikle/Calculation/Model/productCalculator_model.dart';
import 'package:flutter/material.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';


enum PaintLoadState { idle, loadingDropdown, ready, calculating, error }

class PaintCalculatorProvider extends ChangeNotifier {
  PaintLoadState state = PaintLoadState.idle;
  List<PaintDropdownItem> paintOptions = [];
  PaintDropdownItem? selectedPaint;
  PaintEstimateModel? estimate;
  String errorMessage = '';

  // Tracks which variant "Add to Cart" buttons are mid-request, so each
  // button can show its own spinner instead of blocking the whole screen.
  final Set<int> addingToCartVariantIds = {};

  // NEW: the selected paint's product image, pulled from
  // GET api/materials/{material_id}/ ("master_image"). Same image is used
  // for every variant card since all variants belong to this one material.
  String? productImageUrl;
  bool _loadingImage = false;

  final TextEditingController wallLengthCtrl =
      TextEditingController(text: '12');
  final TextEditingController wallHeightCtrl =
      TextEditingController(text: '10');
  final TextEditingController wallsCtrl = TextEditingController(text: '4');
  final TextEditingController coatsCtrl = TextEditingController(text: '2');

  /// GET api/paint/drop-down/ — populates the "Paint type" field.
  /// No longer auto-calculates after loading — user must tap Calculate.
  Future<void> loadDropdown() async {
    state = PaintLoadState.loadingDropdown;
    notifyListeners();
    try {
      paintOptions = await ApiService.getPaintDropdown();
      if (paintOptions.isNotEmpty) {
        selectedPaint = paintOptions.first;
      }
      state = PaintLoadState.idle;
    } catch (e) {
      errorMessage = e.toString();
      state = PaintLoadState.error;
    }
    notifyListeners();
  }

  void selectPaint(PaintDropdownItem item) {
    selectedPaint = item;
    // Selecting a new paint clears the previous estimate/products/image
    // until the user taps Calculate again.
    estimate = null;
    productImageUrl = null;
    notifyListeners();
  }

  /// POST api/calculator/paint/ — only fired by the Calculate button.
  Future<void> calculate() async {
    if (selectedPaint == null) return;
    state = PaintLoadState.calculating;
    notifyListeners();
    try {
      estimate = await ApiService.calculatePaint(
        materialId: selectedPaint!.materialId,
        wallLength: double.tryParse(wallLengthCtrl.text) ?? 0,
        wallHeight: double.tryParse(wallHeightCtrl.text) ?? 0,
        numberOfWalls: int.tryParse(wallsCtrl.text) ?? 0,
        numberOfCoats: int.tryParse(coatsCtrl.text) ?? 0,
      );
      state = PaintLoadState.ready;
      notifyListeners();

      // Fire-and-forget: don't block showing the estimate on the image
      // request finishing. The UI shows a shimmer/fallback until it lands.
      _loadProductImage(selectedPaint!.materialId);
    } catch (e) {
      errorMessage = e.toString();
      state = PaintLoadState.error;
      notifyListeners();
    }
  }

  /// GET api/materials/{material_id}/ — used purely for its `master_image`.
  /// Reuses the same ApiService method your product-detail page already
  /// calls, so no new endpoint/service code was needed.
  Future<void> _loadProductImage(int materialId) async {
    _loadingImage = true;
    try {
      final details = await ApiService.getMaterialDetails(materialId);
      productImageUrl = details['master_image'] as String?;
    } catch (_) {
      // Non-fatal — cards just fall back to a placeholder icon.
      productImageUrl = null;
    }
    _loadingImage = false;
    notifyListeners();
  }

  bool get isLoadingImage => _loadingImage;

  /// Adds one of the suggested variants (from "Available variants in DB")
  /// to the cart. Returns true/false so the screen can show a snackbar.
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
    wallLengthCtrl.dispose();
    wallHeightCtrl.dispose();
    wallsCtrl.dispose();
    coatsCtrl.dispose();
    super.dispose();
  }
}