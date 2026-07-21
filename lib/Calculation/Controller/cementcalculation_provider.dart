// lib/Calculation/Controller/cementcalculation_provider.dart

import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/Calculation/Model/cementCalculation_model.dart';
import 'package:flutter/material.dart';

enum CementCalculatorType { plastering, columnConcrete, roofSlab }

enum CementLoadState { idle, loadingDropdown, ready, calculating, error }

class CementCalculationProvider extends ChangeNotifier {
  CementLoadState state = CementLoadState.idle;
  CementDropdownResponse? dropdownData;
  String errorMessage = '';

  // Current calculator type
  CementCalculatorType currentType = CementCalculatorType.plastering;

  // ─── Shared Data ──────────────────────────────────────────────────────────
  List<ConcreteGrade> concreteGrades = [];

  // ─── Plastering Specific ──────────────────────────────────────────────────
  ThicknessOption? selectedThickness;
  MortarRatio? selectedMortarRatio;
  final TextEditingController wallAreaCtrl = TextEditingController(text: '500');
  final TextEditingController plasterThicknessCtrl = TextEditingController(
    text: '12',
  );

  // ─── Column Concrete Specific ────────────────────────────────────────────
  String selectedConcreteGrade = 'M20';
  final TextEditingController columnCountCtrl = TextEditingController(
    text: '6',
  );
  final TextEditingController columnWidthCtrl = TextEditingController(
    text: '230',
  );
  final TextEditingController columnDepthCtrl = TextEditingController(
    text: '450',
  );
  final TextEditingController columnHeightCtrl = TextEditingController(
    text: '10',
  );

  // ─── Roof Slab Specific ──────────────────────────────────────────────────
  final TextEditingController slabLengthCtrl = TextEditingController(
    text: '30',
  );
  final TextEditingController slabWidthCtrl = TextEditingController(text: '20');
  final TextEditingController roofThicknessCtrl = TextEditingController(
    text: '125',
  );

  // ─── Shared ──────────────────────────────────────────────────────────────
  final TextEditingController cementPriceCtrl = TextEditingController(
    text: '410',
  );

  // ─── Results ─────────────────────────────────────────────────────────────
  dynamic
  estimate; // Can be PlasteringEstimate, ColumnConcreteEstimate, or RoofSlabEstimate
  List<SimilarProduct> similarProducts = [];

  // ─── Product Images ──────────────────────────────────────────────────────
  // Map to store product images by materialId
  final Map<int, String?> _productImages = {};
  bool _loadingImages = false;

  // Track adding to cart
  final Set<int> addingToCartVariantIds = {};

  // ─── Getters ─────────────────────────────────────────────────────────────

  String get currentTitle {
    // switch (currentType) {
    //   case CementCalculatorType.plastering:
    //     return 'Cement Calculator';
    //   case CementCalculatorType.columnConcrete:
    //     return 'Column Concrete Calculator';
    //   case CementCalculatorType.roofSlab:
    //     return 'Roof Slab Calculator';
    // }
    return 'Cement Calculator';
  }

  bool get showPlasteringFields =>
      currentType == CementCalculatorType.plastering;
  bool get showColumnConcreteFields =>
      currentType == CementCalculatorType.columnConcrete;
  bool get showRoofSlabFields => currentType == CementCalculatorType.roofSlab;

  // Get product image URL for a specific material
  String? getProductImage(int materialId) {
    return _productImages[materialId];
  }

  bool get isLoadingImages => _loadingImages;

  // ─── Load Dropdown ──────────────────────────────────────────────────────

  Future<void> loadDropdown() async {
    state = CementLoadState.loadingDropdown;
    notifyListeners();
    try {
      dropdownData = await ApiService.getCementDropdown();

      if (dropdownData != null) {
        // Set plastering defaults
        if (dropdownData!.plasteringOptions.thicknessOptions.isNotEmpty) {
          selectedThickness =
              dropdownData!.plasteringOptions.thicknessOptions.first;
          plasterThicknessCtrl.text = selectedThickness!.valueMm.toString();
        }
        if (dropdownData!.plasteringOptions.mortarRatios.isNotEmpty) {
          selectedMortarRatio =
              dropdownData!.plasteringOptions.mortarRatios.first;
        }
        // Set concrete grades
        concreteGrades = dropdownData!.concreteOptions.mixGrades;
        if (concreteGrades.isNotEmpty) {
          selectedConcreteGrade = concreteGrades.first.value;
        }
      }
      state = CementLoadState.ready;
    } catch (e) {
      errorMessage = e.toString();
      state = CementLoadState.error;
    }
    notifyListeners();
  }

  // ─── Type Switching ─────────────────────────────────────────────────────

  void switchTo(CementCalculatorType type) {
    if (currentType == type) return;
    currentType = type;
    estimate = null;
    similarProducts = [];
    errorMessage = '';
    state = CementLoadState.ready;
    notifyListeners();
  }

  // ─── Selection Methods ─────────────────────────────────────────────────

  void selectThickness(ThicknessOption option) {
    selectedThickness = option;
    plasterThicknessCtrl.text = option.valueMm.toString();
    estimate = null;
    similarProducts = [];
    _productImages.clear(); // Clear old images
    notifyListeners();
  }

  void selectMortarRatio(MortarRatio ratio) {
    selectedMortarRatio = ratio;
    estimate = null;
    similarProducts = [];
    _productImages.clear();
    notifyListeners();
  }

  void selectConcreteGrade(String grade) {
    selectedConcreteGrade = grade;
    estimate = null;
    similarProducts = [];
    _productImages.clear();
    notifyListeners();
  }

  // ─── Calculate ──────────────────────────────────────────────────────────

  Future<void> calculate() async {
    state = CementLoadState.calculating;
    notifyListeners();

    try {
      switch (currentType) {
        case CementCalculatorType.plastering:
          await _calculatePlastering();
          break;
        case CementCalculatorType.columnConcrete:
          await _calculateColumnConcrete();
          break;
        case CementCalculatorType.roofSlab:
          await _calculateRoofSlab();
          break;
      }
      state = CementLoadState.ready;
      notifyListeners();

      // After calculation, load images for all products
      await _loadProductImages();
    } catch (e) {
      errorMessage = e.toString();
      state = CementLoadState.error;
      notifyListeners();
    }
  }

  // ─── Load Product Images ──────────────────────────────────────────────

  Future<void> _loadProductImages() async {
    if (similarProducts.isEmpty) return;

    _loadingImages = true;
    notifyListeners();

    // Load images for each unique material
    final uniqueMaterialIds = similarProducts.map((p) => p.materialId).toSet();

    for (final materialId in uniqueMaterialIds) {
      if (!_productImages.containsKey(materialId)) {
        try {
          final details = await ApiService.getMaterialDetails(materialId);
          _productImages[materialId] = details['master_image'] as String?;
        } catch (_) {
          _productImages[materialId] = null;
        }
      }
    }

    _loadingImages = false;
    notifyListeners();
  }

  // ─── Calculate Methods ─────────────────────────────────────────────────

  Future<void> _calculatePlastering() async {
    if (selectedMortarRatio == null) {
      throw Exception('Please select a mortar ratio');
    }

    final wallArea = double.tryParse(wallAreaCtrl.text);
    final thickness = double.tryParse(plasterThicknessCtrl.text);
    final cementPrice = double.tryParse(cementPriceCtrl.text);

    if (wallArea == null || wallArea <= 0) {
      throw Exception('Please enter a valid wall area');
    }
    if (thickness == null || thickness <= 0) {
      throw Exception('Please enter a valid thickness');
    }
    if (cementPrice == null || cementPrice <= 0) {
      throw Exception('Please enter a valid cement price');
    }

    final result = await ApiService.calculatePlastering(
      wallArea: wallArea,
      thicknessMm: thickness,
      mortarRatio: selectedMortarRatio!.value,
      cementBagPrice: cementPrice,
    );
    estimate = result.estimate;
    similarProducts = result.similarProducts;
  }

  Future<void> _calculateColumnConcrete() async {
    final count = int.tryParse(columnCountCtrl.text);
    final width = double.tryParse(columnWidthCtrl.text);
    final depth = double.tryParse(columnDepthCtrl.text);
    final height = double.tryParse(columnHeightCtrl.text);
    final cementPrice = double.tryParse(cementPriceCtrl.text);

    if (count == null || count <= 0) {
      throw Exception('Please enter a valid number of columns');
    }
    if (width == null || width <= 0) {
      throw Exception('Please enter a valid column width');
    }
    if (depth == null || depth <= 0) {
      throw Exception('Please enter a valid column depth');
    }
    if (height == null || height <= 0) {
      throw Exception('Please enter a valid column height');
    }
    if (cementPrice == null || cementPrice <= 0) {
      throw Exception('Please enter a valid cement price');
    }

    final result = await ApiService.calculateColumnConcrete(
      numberOfColumns: count,
      concreteGrade: selectedConcreteGrade,
      columnWidthMm: width,
      columnDepthMm: depth,
      columnHeightFt: height,
      cementBagPrice: cementPrice,
    );
    estimate = result.estimate;
    similarProducts = result.similarProducts;
  }

  Future<void> _calculateRoofSlab() async {
    final length = double.tryParse(slabLengthCtrl.text);
    final width = double.tryParse(slabWidthCtrl.text);
    final thickness = double.tryParse(roofThicknessCtrl.text);
    final cementPrice = double.tryParse(cementPriceCtrl.text);

    if (length == null || length <= 0) {
      throw Exception('Please enter a valid slab length');
    }
    if (width == null || width <= 0) {
      throw Exception('Please enter a valid slab width');
    }
    if (thickness == null || thickness <= 0) {
      throw Exception('Please enter a valid thickness');
    }
    if (cementPrice == null || cementPrice <= 0) {
      throw Exception('Please enter a valid cement price');
    }

    final result = await ApiService.calculateRoofSlab(
      slabLength: length,
      slabWidth: width,
      thicknessMm: thickness,
      concreteGrade: selectedConcreteGrade,
      cementBagPrice: cementPrice,
    );
    estimate = result.estimate;
    similarProducts = result.similarProducts;
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
    wallAreaCtrl.dispose();
    plasterThicknessCtrl.dispose();
    columnCountCtrl.dispose();
    columnWidthCtrl.dispose();
    columnDepthCtrl.dispose();
    columnHeightCtrl.dispose();
    slabLengthCtrl.dispose();
    slabWidthCtrl.dispose();
    roofThicknessCtrl.dispose();
    cementPriceCtrl.dispose();
    super.dispose();
  }
}
