// lib/Calculation/Model/shared_calculator_models.dart

/// Shared models used across all calculator types

// ─── Plastering Models ──────────────────────────────────────────────────────

class ThicknessOption {
  final String label;
  final int valueMm;

  ThicknessOption({required this.label, required this.valueMm});

  factory ThicknessOption.fromJson(Map<String, dynamic> json) {
    return ThicknessOption(
      label: json['label'] ?? '',
      valueMm: json['value_mm'] ?? 0,
    );
  }
}

class MortarRatio {
  final String label;
  final String value;

  MortarRatio({required this.label, required this.value});

  factory MortarRatio.fromJson(Map<String, dynamic> json) {
    return MortarRatio(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }
}

class PlasteringOptions {
  final List<ThicknessOption> thicknessOptions;
  final List<MortarRatio> mortarRatios;

  PlasteringOptions({
    required this.thicknessOptions,
    required this.mortarRatios,
  });

  factory PlasteringOptions.fromJson(Map<String, dynamic> json) {
    return PlasteringOptions(
      thicknessOptions: (json['thickness_options'] as List? ?? [])
          .map((e) => ThicknessOption.fromJson(e))
          .toList(),
      mortarRatios: (json['mortar_ratios'] as List? ?? [])
          .map((e) => MortarRatio.fromJson(e))
          .toList(),
    );
  }
}

// ─── Concrete Models ────────────────────────────────────────────────────────

class ConcreteGrade {
  final String label;
  final String value;
  final String ratio;

  ConcreteGrade({required this.label, required this.value, required this.ratio});

  factory ConcreteGrade.fromJson(Map<String, dynamic> json) {
    return ConcreteGrade(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
      ratio: json['ratio'] ?? '',
    );
  }
}

class ConcreteOptions {
  final List<ConcreteGrade> mixGrades;

  ConcreteOptions({required this.mixGrades});

  factory ConcreteOptions.fromJson(Map<String, dynamic> json) {
    return ConcreteOptions(
      mixGrades: (json['mix_grades'] as List? ?? [])
          .map((e) => ConcreteGrade.fromJson(e))
          .toList(),
    );
  }
}

// ─── Dropdown Response ──────────────────────────────────────────────────────

class CementDropdownResponse {
  final String status;
  final PlasteringOptions plasteringOptions;
  final ConcreteOptions concreteOptions;

  CementDropdownResponse({
    required this.status,
    required this.plasteringOptions,
    required this.concreteOptions,
  });

  factory CementDropdownResponse.fromJson(Map<String, dynamic> json) {
    return CementDropdownResponse(
      status: json['status'] ?? '',
      plasteringOptions: PlasteringOptions.fromJson(json['plastering_options'] ?? {}),
      concreteOptions: ConcreteOptions.fromJson(json['concrete_options'] ?? {}),
    );
  }
}

// ─── Similar Products ──────────────────────────────────────────────────────

class SimilarProduct {
  final int materialId;
  final int variantId;
  final String productName;
  final String packSize;
  final String pricePerBag;
  final String totalCostForRequiredBags;
  final int stock;
  final String stockStatus;

  SimilarProduct({
    required this.materialId,
    required this.variantId,
    required this.productName,
    required this.packSize,
    required this.pricePerBag,
    required this.totalCostForRequiredBags,
    required this.stock,
    required this.stockStatus,
  });

  factory SimilarProduct.fromJson(Map<String, dynamic> json) {
    return SimilarProduct(
      materialId: json['material_id'] ?? 0,
      variantId: json['variant_id'] ?? 0,
      productName: json['product_name'] ?? '',
      packSize: json['pack_size'] ?? '',
      pricePerBag: json['price_per_bag'] ?? '',
      totalCostForRequiredBags: json['total_cost_for_required_bags'] ?? '',
      stock: json['stock'] ?? 0,
      stockStatus: json['stock_status'] ?? '',
    );
  }
}

// ─── Estimate Models ──────────────────────────────────────────────────────

class PlasteringEstimate {
  final String wetMortarVolume;
  final String cementBags;
  final String sand;
  final String userEstimatedCost;

  PlasteringEstimate({
    required this.wetMortarVolume,
    required this.cementBags,
    required this.sand,
    required this.userEstimatedCost,
  });

  factory PlasteringEstimate.fromJson(Map<String, dynamic> json) {
    return PlasteringEstimate(
      wetMortarVolume: json['Wet mortar volume'] ?? '',
      cementBags: json['Cement bags'] ?? '',
      sand: json['Sand'] ?? '',
      userEstimatedCost: json['User Estimated Cost'] ?? '',
    );
  }
}

class ColumnConcreteEstimate {
  final String concreteVolume;
  final String cementBags;
  final String sand;
  final String aggregate;
  final String userEstimatedCost;

  ColumnConcreteEstimate({
    required this.concreteVolume,
    required this.cementBags,
    required this.sand,
    required this.aggregate,
    required this.userEstimatedCost,
  });

  factory ColumnConcreteEstimate.fromJson(Map<String, dynamic> json) {
    return ColumnConcreteEstimate(
      concreteVolume: json['Concrete volume'] ?? '',
      cementBags: json['Cement bags'] ?? '',
      sand: json['Sand'] ?? '',
      aggregate: json['20mm aggregate'] ?? '',
      userEstimatedCost: json['User Estimated Cost'] ?? '',
    );
  }
}

class RoofSlabEstimate {
  final String concreteVolume;
  final String cementBags;
  final String sand;
  final String aggregate;
  final String userEstimatedCost;

  RoofSlabEstimate({
    required this.concreteVolume,
    required this.cementBags,
    required this.sand,
    required this.aggregate,
    required this.userEstimatedCost,
  });

  factory RoofSlabEstimate.fromJson(Map<String, dynamic> json) {
    return RoofSlabEstimate(
      concreteVolume: json['Concrete volume'] ?? '',
      cementBags: json['Cement bags'] ?? '',
      sand: json['Sand'] ?? '',
      aggregate: json['20mm aggregate'] ?? '',
      userEstimatedCost: json['User Estimated Cost'] ?? '',
    );
  }
}

// ─── Response Models ──────────────────────────────────────────────────────

class PlasteringCalculatorResponse {
  final String status;
  final PlasteringEstimate estimate;
  final List<SimilarProduct> similarProducts;

  PlasteringCalculatorResponse({
    required this.status,
    required this.estimate,
    required this.similarProducts,
  });

  factory PlasteringCalculatorResponse.fromJson(Map<String, dynamic> json) {
    return PlasteringCalculatorResponse(
      status: json['status'] ?? '',
      estimate: PlasteringEstimate.fromJson(json['estimate'] ?? {}),
      similarProducts: (json['similar_products'] as List? ?? [])
          .map((e) => SimilarProduct.fromJson(e))
          .toList(),
    );
  }
}

class ColumnConcreteCalculatorResponse {
  final String status;
  final ColumnConcreteEstimate estimate;
  final List<SimilarProduct> similarProducts;

  ColumnConcreteCalculatorResponse({
    required this.status,
    required this.estimate,
    required this.similarProducts,
  });

  factory ColumnConcreteCalculatorResponse.fromJson(Map<String, dynamic> json) {
    return ColumnConcreteCalculatorResponse(
      status: json['status'] ?? '',
      estimate: ColumnConcreteEstimate.fromJson(json['estimate'] ?? {}),
      similarProducts: (json['similar_products'] as List? ?? [])
          .map((e) => SimilarProduct.fromJson(e))
          .toList(),
    );
  }
}

class RoofSlabCalculatorResponse {
  final String status;
  final RoofSlabEstimate estimate;
  final List<SimilarProduct> similarProducts;

  RoofSlabCalculatorResponse({
    required this.status,
    required this.estimate,
    required this.similarProducts,
  });

  factory RoofSlabCalculatorResponse.fromJson(Map<String, dynamic> json) {
    return RoofSlabCalculatorResponse(
      status: json['status'] ?? '',
      estimate: RoofSlabEstimate.fromJson(json['estimate'] ?? {}),
      similarProducts: (json['similar_products'] as List? ?? [])
          .map((e) => SimilarProduct.fromJson(e))
          .toList(),
    );
  }
}