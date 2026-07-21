
// lib/Calculation/Controller/steel_calculator_provider.dart

import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Calculation/Model/steelCalculation_model.dart';
import 'package:flutter/material.dart';

enum SteelLoadState { idle, ready, calculating, error }

class SteelCalculatorProvider extends ChangeNotifier {
  SteelLoadState state = SteelLoadState.idle;
  SteelEstimate? estimate;
  List<dynamic> similarProducts = [];
  String errorMessage = '';

  // Controllers
  final TextEditingController pricePerKgCtrl = TextEditingController(text: '62');

  // Steel items list
  List<SteelItem> steelItems = [];

  // Track adding to cart
  final Set<int> addingToCartVariantIds = {};

  // ─── Initialize with default items ──────────────────────────────────────

  SteelCalculatorProvider() {
    _initializeDefaultItems();
  }

  void _initializeDefaultItems() {
    steelItems = [
      SteelItem(diameter: 8, noOfRods: 50, lengthPerRod: 12),
      SteelItem(diameter: 10, noOfRods: 30, lengthPerRod: 12),
      SteelItem(diameter: 12, noOfRods: 25, lengthPerRod: 12),
    ];
    state = SteelLoadState.ready;
    notifyListeners();
  }

  // ─── Getters ─────────────────────────────────────────────────────────────

  int get totalItems => steelItems.length;

  // ─── Item Management ────────────────────────────────────────────────────

  void addSteelItem() {
    steelItems.add(SteelItem(diameter: 8, noOfRods: 1, lengthPerRod: 12));
    estimate = null;
    similarProducts = [];
    notifyListeners();
  }

  void removeSteelItem(int index) {
    if (steelItems.length > 1) {
      steelItems.removeAt(index);
      estimate = null;
      similarProducts = [];
      notifyListeners();
    }
  }

  void updateSteelItem(int index, SteelItem item) {
    steelItems[index] = item;
    estimate = null;
    similarProducts = [];
    notifyListeners();
  }

  // ─── Calculate ──────────────────────────────────────────────────────────

  Future<void> calculate() async {
    final pricePerKg = double.tryParse(pricePerKgCtrl.text);

    if (pricePerKg == null || pricePerKg <= 0) {
      errorMessage = 'Please enter a valid price per kg';
      state = SteelLoadState.error;
      notifyListeners();
      return;
    }

    // Validate items
    for (var item in steelItems) {
      if (item.diameter <= 0) {
        errorMessage = 'Please enter valid diameters for all items';
        state = SteelLoadState.error;
        notifyListeners();
        return;
      }
      if (item.noOfRods <= 0) {
        errorMessage = 'Please enter valid number of rods for all items';
        state = SteelLoadState.error;
        notifyListeners();
        return;
      }
      if (item.lengthPerRod <= 0) {
        errorMessage = 'Please enter valid length per rod for all items';
        state = SteelLoadState.error;
        notifyListeners();
        return;
      }
    }

    state = SteelLoadState.calculating;
    notifyListeners();

    try {
      final result = await ApiService.calculateSteel(
        pricePerKg: pricePerKg,
        items: steelItems,
      );

      estimate = result.estimate;
      similarProducts = result.similarProducts;
      state = SteelLoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = SteelLoadState.error;
    }
    notifyListeners();
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
    pricePerKgCtrl.dispose();
    super.dispose();
  }
}