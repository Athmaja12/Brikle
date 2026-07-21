// lib/Calculation/Controller/block_calculator_provider.dart

import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Calculation/Controller/blockCalculation_provider.dart';
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
    } catch (e) {
      errorMessage = e.toString();
      state = BlockLoadState.error;
    }
    notifyListeners();
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