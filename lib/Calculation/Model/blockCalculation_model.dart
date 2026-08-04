// lib/Calculation/Model/block_calculator_model.dart

class BlockSizeOption {
  final String label;
  final int lengthMm;
  final int heightMm;
  final int thicknessMm;

  BlockSizeOption({
    required this.label,
    required this.lengthMm,
    required this.heightMm,
    required this.thicknessMm,
  });

  factory BlockSizeOption.fromJson(Map<String, dynamic> json) {
    return BlockSizeOption(
      label: json['label'] ?? '',
      lengthMm: json['length_mm'] ?? 0,
      heightMm: json['height_mm'] ?? 0,
      thicknessMm: json['thickness_mm'] ?? 0,
    );
  }

  String get displayName {
    return label;
  }
}

class WastageOption {
  final String label;
  final int valuePercent;

  WastageOption({required this.label, required this.valuePercent});

  factory WastageOption.fromJson(Map<String, dynamic> json) {
    return WastageOption(
      label: json['label'] ?? '',
      valuePercent: json['value_percent'] ?? 0,
    );
  }
}

class BlockDropdownResponse {
  final String status;
  final List<BlockSizeOption> blockSizeOptions;
  final List<WastageOption> wastageOptions;

  BlockDropdownResponse({
    required this.status,
    required this.blockSizeOptions,
    required this.wastageOptions,
  });

  factory BlockDropdownResponse.fromJson(Map<String, dynamic> json) {
    return BlockDropdownResponse(
      status: json['status'] ?? '',
      blockSizeOptions: (json['block_size_options'] as List? ?? [])
          .map((e) => BlockSizeOption.fromJson(e))
          .toList(),
      wastageOptions: (json['wastage_options'] as List? ?? [])
          .map((e) => WastageOption.fromJson(e))
          .toList(),
    );
  }
}

class BlockInputs {
  final double wallAreaSqft;
  final String selectedBlock;
  final String selectedAdhesive;

  BlockInputs({
    required this.wallAreaSqft,
    required this.selectedBlock,
    required this.selectedAdhesive,
  });

  factory BlockInputs.fromJson(Map<String, dynamic> json) {
    return BlockInputs(
      wallAreaSqft: json['wall_area_sqft']?.toDouble() ?? 0.0,
      selectedBlock: json['selected_block'] ?? '',
      selectedAdhesive: json['selected_adhesive'] ?? '',
    );
  }
}

class BlockEstimate {
  final int blocksWithWastage;
  final String adhesiveBags;
  final String blockCost;
  final String adhesiveCost;
  final String totalEstimate;

  BlockEstimate({
    required this.blocksWithWastage,
    required this.adhesiveBags,
    required this.blockCost,
    required this.adhesiveCost,
    required this.totalEstimate,
  });

  factory BlockEstimate.fromJson(Map<String, dynamic> json) {
    return BlockEstimate(
      blocksWithWastage: json['blocks_with_wastage'] ?? 0,
      adhesiveBags: json['adhesive_bags'] ?? '',
      blockCost: json['block_cost'] ?? '',
      adhesiveCost: json['adhesive_cost'] ?? '',
      totalEstimate: json['total_estimate'] ?? '',
    );
  }
}

class RelatedBlockProduct {
  final int materialId;
  final int variantId;
  final String name;
  final double pricePerUnit;
  final num totalCost;

  // Populated later via a separate materials-detail call — not in the
  // block-calculator response itself.
  String? imageUrl;
  bool imageLoading;

  RelatedBlockProduct({
    required this.materialId,
    required this.variantId,
    required this.name,
    required this.pricePerUnit,
    required this.totalCost,
    this.imageUrl,
    this.imageLoading = false,
  });

  factory RelatedBlockProduct.fromJson(Map<String, dynamic> json) {
    return RelatedBlockProduct(
      materialId: json['material_id'] ?? 0,
      variantId: json['variant_id'] ?? 0,
      name: json['name']?.toString() ?? '',
      pricePerUnit: (json['price_per_unit'] as num?)?.toDouble() ?? 0.0,
      totalCost: json['total_cost_for_estimated_blocks'] ?? 0,
    );
  }
}

class RelatedProducts {
  final List<RelatedBlockProduct> blocks;
  final List<RelatedBlockProduct> adhesives;

  RelatedProducts({required this.blocks, required this.adhesives});

  factory RelatedProducts.fromJson(Map<String, dynamic> json) {
    return RelatedProducts(
      blocks: (json['blocks'] as List? ?? [])
          .map((e) => RelatedBlockProduct.fromJson(e))
          .toList(),
      adhesives: (json['adhesives'] as List? ?? [])
          .map((e) => RelatedBlockProduct.fromJson(e))
          .toList(),
    );
  }
}

class BlockCalculatorResponse {
  final String status;
  final BlockInputs inputs;
  final BlockEstimate estimate;
  final RelatedProducts relatedProducts;

  BlockCalculatorResponse({
    required this.status,
    required this.inputs,
    required this.estimate,
    required this.relatedProducts,
  });

  factory BlockCalculatorResponse.fromJson(Map<String, dynamic> json) {
    return BlockCalculatorResponse(
      status: json['status'] ?? '',
      inputs: BlockInputs.fromJson(json['inputs'] ?? {}),
      estimate: BlockEstimate.fromJson(json['estimate'] ?? {}),
      relatedProducts: RelatedProducts.fromJson(json['related_products'] ?? {}),
    );
  }
}