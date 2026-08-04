// lib/Calculation/Controller/block_calculator_provider.dart

import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Calculation/Model/blockCalculation_model.dart';
import 'package:brikle/Product/Model/productdetails_model.dart';
import 'package:flutter/material.dart';

enum BlockLoadState { idle, loadingDropdown, ready, calculating, error }

class BlockCalculatorProvider extends ChangeNotifier {
  BlockLoadState state = BlockLoadState.idle;
  BlockDropdownResponse? dropdownData;
  BlockCalculatorResponse? calculationResult;
  String errorMessage = '';

  // ─── Selected Values ──────────────────────────────────────────────────
  BlockSizeOption? selectedBlockSize;
  WastageOption? selectedWastage;

  // ─── Controllers ─────────────────────────────────────────────────────
  final TextEditingController wallLengthCtrl = TextEditingController(text: '20');
  final TextEditingController wallHeightCtrl = TextEditingController(text: '10');

  // ─── Track adding to cart ────────────────────────────────────────────
  final Set<int> addingToCartVariantIds = {};

  // ─── Getters ─────────────────────────────────────────────────────────

  bool get hasDropdownData => dropdownData != null;
  bool get hasCalculation => calculationResult != null;

  // ─── Load Dropdown ──────────────────────────────────────────────────

  Future<void> loadDropdown() async {
    state = BlockLoadState.loadingDropdown;
    notifyListeners();

    try {
      dropdownData = await ApiService.getBlockDropdown();

      if (dropdownData != null) {
        // Set default selections
        if (dropdownData!.blockSizeOptions.isNotEmpty) {
          selectedBlockSize = dropdownData!.blockSizeOptions.first;
        }
        if (dropdownData!.wastageOptions.isNotEmpty) {
          selectedWastage = dropdownData!.wastageOptions.first;
        }
      }

      state = BlockLoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = BlockLoadState.error;
    }
    notifyListeners();
  }

  // ─── Selection Methods ──────────────────────────────────────────────

  void selectBlockSize(BlockSizeOption option) {
    selectedBlockSize = option;
    calculationResult = null;
    notifyListeners();
  }

  void selectWastage(WastageOption option) {
    selectedWastage = option;
    calculationResult = null;
    notifyListeners();
  }

  // ─── Calculate ──────────────────────────────────────────────────────

  Future<void> calculate() async {
    if (selectedBlockSize == null || selectedWastage == null) {
      errorMessage = 'Please select block size and wastage percentage';
      state = BlockLoadState.error;
      notifyListeners();
      return;
    }

    final length = double.tryParse(wallLengthCtrl.text);
    final height = double.tryParse(wallHeightCtrl.text);

    if (length == null || length <= 0) {
      errorMessage = 'Please enter a valid wall length';
      state = BlockLoadState.error;
      notifyListeners();
      return;
    }

    if (height == null || height <= 0) {
      errorMessage = 'Please enter a valid wall height';
      state = BlockLoadState.error;
      notifyListeners();
      return;
    }

    state = BlockLoadState.calculating;
    notifyListeners();

    try {
      final result = await ApiService.calculateBlock(
        wallLengthFt: length,
        wallHeightFt: height,
        wastagePercent: selectedWastage!.valuePercent,
        blockLengthMm: selectedBlockSize!.lengthMm,
        blockHeightMm: selectedBlockSize!.heightMm,
        blockThicknessMm: selectedBlockSize!.thicknessMm,
      );

      calculationResult = result;
      state = BlockLoadState.ready;

      // 🔎 DEBUG — confirm the raw related_products payload actually
      // arrived and was parsed into the right number of items.
      debugPrint(
        '[BlockCalculator] calculate() success. '
        'blocks=${result.relatedProducts.blocks.length}, '
        'adhesives=${result.relatedProducts.adhesives.length}',
      );
      for (final b in result.relatedProducts.blocks) {
        debugPrint(
          '[BlockCalculator]   block -> materialId=${b.materialId}, '
          'variantId=${b.variantId}, name="${b.name}", '
          'price=${b.pricePerUnit}, total=${b.totalCost}',
        );
      }
      for (final a in result.relatedProducts.adhesives) {
        debugPrint(
          '[BlockCalculator]   adhesive -> materialId=${a.materialId}, '
          'variantId=${a.variantId}, name="${a.name}"',
        );
      }
    } catch (e) {
      errorMessage = e.toString();
      state = BlockLoadState.error;
      debugPrint('[BlockCalculator] calculate() FAILED: $e');
    }
    notifyListeners();

    if (state == BlockLoadState.ready) {
      // fire-and-forget — don't block the Calculate button on image loads
      _loadRelatedProductImages();
    }
  }

  // ─── Related Product Images ─────────────────────────────────────────

  Future<void> _loadRelatedProductImages() async {
    final all = [
      ...?calculationResult?.relatedProducts.blocks,
      ...?calculationResult?.relatedProducts.adhesives,
    ];

    debugPrint('[BlockCalculator] _loadRelatedProductImages: ${all.length} item(s) to fetch');

    if (all.isEmpty) return;

    for (final product in all) {
      product.imageLoading = true;
    }
    notifyListeners();

    for (final product in all) {
      try {
        debugPrint(
          '[BlockCalculator]   fetching material detail for materialId=${product.materialId} (${product.name})',
        );
        final json = await ApiService.getMaterialDetails(product.materialId);
        final detail = MaterialDetail.fromJson(json);
        product.imageUrl = detail.masterImage;
        debugPrint(
          '[BlockCalculator]   -> resolved image for materialId=${product.materialId}: '
          '"${product.imageUrl}"',
        );
        if (product.imageUrl == null || product.imageUrl!.isEmpty) {
          debugPrint(
            '[BlockCalculator]   ⚠️ empty master_image for materialId=${product.materialId} — '
            'check backend response for this material.',
          );
        }
      } catch (e) {
        product.imageUrl = null;
        debugPrint(
          '[BlockCalculator]   ⚠️ FAILED to fetch material ${product.materialId}: $e',
        );
      } finally {
        product.imageLoading = false;
        notifyListeners();
      }
    }
  }

  // ─── Cart Methods ──────────────────────────────────────────────────

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
    super.dispose();
  }
}