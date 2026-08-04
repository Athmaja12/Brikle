// lib/Calculation/Model/steel_calculator_model.dart

class SteelItem {
  final int diameter;
  final int noOfRods;
  final double lengthPerRod;

  SteelItem({
    required this.diameter,
    required this.noOfRods,
    required this.lengthPerRod,
  });

  Map<String, dynamic> toJson() {
    return {
      'diameter': diameter,
      'no_of_rods': noOfRods,
      'length_per_rod': lengthPerRod,
    };
  }

  factory SteelItem.fromJson(Map<String, dynamic> json) {
    return SteelItem(
      diameter: json['diameter'] ?? 0,
      noOfRods: json['no_of_rods'] ?? 0,
      lengthPerRod: json['length_per_rod'] ?? 0.0,
    );
  }
}

class SteelRowEstimate {
  final String description;
  final double rowWeightKg;

  SteelRowEstimate({
    required this.description,
    required this.rowWeightKg,
  });

  factory SteelRowEstimate.fromJson(Map<String, dynamic> json) {
    return SteelRowEstimate(
      description: json['description'] ?? '',
      rowWeightKg: json['row_weight_kg']?.toDouble() ?? 0.0,
    );
  }
}

class SteelEstimate {
  final List<SteelRowEstimate> rows;
  final String totalWeight;
  final String inTonnes;
  final String userEstimatedCost;

  SteelEstimate({
    required this.rows,
    required this.totalWeight,
    required this.inTonnes,
    required this.userEstimatedCost,
  });

  factory SteelEstimate.fromJson(Map<String, dynamic> json) {
    return SteelEstimate(
      rows: (json['rows'] as List? ?? [])
          .map((e) => SteelRowEstimate.fromJson(e))
          .toList(),
      totalWeight: json['Total weight'] ?? '',
      inTonnes: json['In tonnes'] ?? '',
      userEstimatedCost: json['User Estimated Cost'] ?? '',
    );
  }
}

// ─── NEW: typed similar-product model (was List<dynamic>) ────────────────

class SimilarSteelProduct {
  final int materialId;
  final int variantId;
  final String productName;
  final String unitStyle;
  final String pricePerUnit;
  final String totalCostForRequiredWeight;
  final int stock;
  final String stockStatus;

  // Populated later via a separate materials-detail call — not present
  // in the steel-calculator response itself.
  String? imageUrl;
  bool imageLoading;

  SimilarSteelProduct({
    required this.materialId,
    required this.variantId,
    required this.productName,
    required this.unitStyle,
    required this.pricePerUnit,
    required this.totalCostForRequiredWeight,
    required this.stock,
    required this.stockStatus,
    this.imageUrl,
    this.imageLoading = false,
  });

  bool get inStock => stock > 0;

  factory SimilarSteelProduct.fromJson(Map<String, dynamic> json) {
    return SimilarSteelProduct(
      materialId: json['material_id'] ?? 0,
      variantId: json['variant_id'] ?? 0,
      productName: json['product_name']?.toString() ?? '',
      unitStyle: json['unit_style']?.toString() ?? '',
      pricePerUnit: json['price_per_unit']?.toString() ?? '',
      totalCostForRequiredWeight:
          json['total_cost_for_required_weight']?.toString() ?? '',
      stock: json['stock'] ?? 0,
      stockStatus: json['stock_status']?.toString() ?? '',
    );
  }
}

class SteelCalculatorResponse {
  final String status;
  final SteelEstimate estimate;
  final List<SimilarSteelProduct> similarProducts; // ← was List<dynamic>

  SteelCalculatorResponse({
    required this.status,
    required this.estimate,
    required this.similarProducts,
  });

  factory SteelCalculatorResponse.fromJson(Map<String, dynamic> json) {
    return SteelCalculatorResponse(
      status: json['status'] ?? '',
      estimate: SteelEstimate.fromJson(json['estimate'] ?? {}),
      similarProducts: (json['similar_products'] as List? ?? [])
          .map((e) => SimilarSteelProduct.fromJson(e))
          .toList(),
    );
  }
}