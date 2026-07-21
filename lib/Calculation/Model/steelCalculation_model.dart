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

class SteelCalculatorResponse {
  final String status;
  final SteelEstimate estimate;
  final List<dynamic> similarProducts;

  SteelCalculatorResponse({
    required this.status,
    required this.estimate,
    required this.similarProducts,
  });

  factory SteelCalculatorResponse.fromJson(Map<String, dynamic> json) {
    return SteelCalculatorResponse(
      status: json['status'] ?? '',
      estimate: SteelEstimate.fromJson(json['estimate'] ?? {}),
      similarProducts: json['similar_products'] ?? [],
    );
  }
}