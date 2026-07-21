// lib/Calculation/Model/waterproofing_calculator_model.dart

// ─── Product Model ──────────────────────────────────────────────────────────

class WaterproofingProduct {
  final int materialId;
  final int variantId;
  final String name;
  final String packsNeeded;
  final double pricePerPack;
  final int totalCost;
  final int rawPacks;

  WaterproofingProduct({
    required this.materialId,
    required this.variantId,
    required this.name,
    required this.packsNeeded,
    required this.pricePerPack,
    required this.totalCost,
    required this.rawPacks,
  });

  factory WaterproofingProduct.fromJson(Map<String, dynamic> json) {
    return WaterproofingProduct(
      materialId: json['material_id'] ?? 0,
      variantId: json['variant_id'] ?? 0,
      name: json['name'] ?? '',
      packsNeeded: json['packs_needed'] ?? '',
      pricePerPack: json['price_per_pack']?.toDouble() ?? 0.0,
      totalCost: json['total_cost'] ?? 0,
      rawPacks: json['raw_packs'] ?? 0,
    );
  }
}

// ─── Related Products ──────────────────────────────────────────────────────

class RelatedProducts {
  final List<WaterproofingProduct> waterproofing;
  final List<WaterproofingProduct> admixture;

  RelatedProducts({
    required this.waterproofing,
    required this.admixture,
  });

  factory RelatedProducts.fromJson(Map<String, dynamic> json) {
    return RelatedProducts(
      waterproofing: (json['waterproofing'] as List? ?? [])
          .map((e) => WaterproofingProduct.fromJson(e))
          .toList(),
      admixture: (json['admixture'] as List? ?? [])
          .map((e) => WaterproofingProduct.fromJson(e))
          .toList(),
    );
  }
}

// ─── Response Models ──────────────────────────────────────────────────────

class WaterproofingInputs {
  final double? terraceAreaSqft;
  final int? coatsApplied;
  final String selectedProduct;
  final double? floorAreaSqft;
  final double? wallCoatAreaSqft;
  final double? totalAreaSqft;
  final double? tankLengthFt;
  final double? tankWidthFt;
  final double? tankHeightFt;
  final int? numberOfWallsCoated;
  final double? wallAreaSqft;
  final double? insideSurfaceAreaSqft;
  final double? wallAreaSqft2;
  final int? numberOfCementBags;

  WaterproofingInputs({
    this.terraceAreaSqft,
    this.coatsApplied,
    required this.selectedProduct,
    this.floorAreaSqft,
    this.wallCoatAreaSqft,
    this.totalAreaSqft,
    this.tankLengthFt,
    this.tankWidthFt,
    this.tankHeightFt,
    this.numberOfWallsCoated,
    this.wallAreaSqft,
    this.insideSurfaceAreaSqft,
    this.wallAreaSqft2,
    this.numberOfCementBags,
  });

  factory WaterproofingInputs.fromJson(Map<String, dynamic> json) {
    return WaterproofingInputs(
      terraceAreaSqft: json['terrace_area_sqft']?.toDouble(),
      coatsApplied: json['coats_applied'],
      selectedProduct: json['selected_product'] ?? '',
      floorAreaSqft: json['floor_area_sqft']?.toDouble(),
      wallCoatAreaSqft: json['wall_coat_area_sqft']?.toDouble(),
      totalAreaSqft: json['total_area_sqft']?.toDouble(),
      tankLengthFt: json['tank_length_ft']?.toDouble(),
      tankWidthFt: json['tank_width_ft']?.toDouble(),
      tankHeightFt: json['tank_height_ft']?.toDouble(),
      numberOfWallsCoated: json['number_of_walls_coated'],
      wallAreaSqft: json['wall_area_sqft']?.toDouble(),
      insideSurfaceAreaSqft: json['inside_surface_area_sqft']?.toDouble(),
      wallAreaSqft2: json['wall_area_sqft']?.toDouble(),
      numberOfCementBags: json['number_of_cement_bags'],
    );
  }
}

class WaterproofingEstimate {
  final String? materialRequiredLitres;
  final String? bucketsNeeded;
  final String? materialRequiredKg;
  final String? packsNeeded;
  final String? kitsNeeded;
  final String? totalDosage;
  final String? litresNeeded;
  final String? suggestedPacks;
  final String materialCost;
  final String totalEstimate;

  WaterproofingEstimate({
    this.materialRequiredLitres,
    this.bucketsNeeded,
    this.materialRequiredKg,
    this.packsNeeded,
    this.kitsNeeded,
    this.totalDosage,
    this.litresNeeded,
    this.suggestedPacks,
    required this.materialCost,
    required this.totalEstimate,
  });

  factory WaterproofingEstimate.fromJson(Map<String, dynamic> json) {
    return WaterproofingEstimate(
      materialRequiredLitres: json['material_required_litres'],
      bucketsNeeded: json['buckets_needed'],
      materialRequiredKg: json['material_required_kg'],
      packsNeeded: json['packs_needed'],
      kitsNeeded: json['kits_needed'],
      totalDosage: json['total_dosage'],
      litresNeeded: json['litres_needed'],
      suggestedPacks: json['suggested_packs'],
      materialCost: json['material_cost'] ?? '',
      totalEstimate: json['total_estimate'] ?? '',
    );
  }
}

class WaterproofingCalculatorResponse {
  final String status;
  final WaterproofingInputs inputs;
  final WaterproofingEstimate estimate;
  final RelatedProducts relatedProducts;

  WaterproofingCalculatorResponse({
    required this.status,
    required this.inputs,
    required this.estimate,
    required this.relatedProducts,
  });

  factory WaterproofingCalculatorResponse.fromJson(Map<String, dynamic> json) {
    return WaterproofingCalculatorResponse(
      status: json['status'] ?? '',
      inputs: WaterproofingInputs.fromJson(json['inputs'] ?? {}),
      estimate: WaterproofingEstimate.fromJson(json['estimate'] ?? {}),
      relatedProducts: RelatedProducts.fromJson(json['related_products'] ?? {}),
    );
  }
}