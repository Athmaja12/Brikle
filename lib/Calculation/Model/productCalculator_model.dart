// model/paint_calculator_model.dart
//
// Maps to:
//   GET  api/paint/drop-down/     -> List<PaintDropdownItem>
//   POST api/calculator/paint/    -> PaintEstimateModel

class PaintDropdownItem {
  final int materialId;
  final String displayName;
  final String paintType;
  final int coverage;

  PaintDropdownItem({
    required this.materialId,
    required this.displayName,
    required this.paintType,
    required this.coverage,
  });

  factory PaintDropdownItem.fromJson(Map<String, dynamic> json) {
    return PaintDropdownItem(
      materialId: json['material_id'] ?? 0,
      displayName: json['display_name'] ?? '',
      paintType: json['paint_type'] ?? '',
      coverage: json['coverage'] ?? 0,
    );
  }
}

class PaintVariant {
  final int variantId;
  final String packSize;
  final String price;
  final String stockStatus;

  PaintVariant({
    required this.variantId,
    required this.packSize,
    required this.price,
    required this.stockStatus,
  });

  factory PaintVariant.fromJson(Map<String, dynamic> json) {
    return PaintVariant(
      variantId: json['variant_id'] ?? 0,
      packSize: json['pack_size'] ?? '',
      price: json['price'] ?? '',
      stockStatus: json['stock_status'] ?? '',
    );
  }
}

/// The `estimate` object returned by POST api/calculator/paint/
class PaintEstimateModel {
  final String product;
  final String wallArea;
  final String totalPaintingArea;
  final String paintRequired;
  final String suggestedPack;
  final String estimatedCost;
  final List<PaintVariant> variants;

  PaintEstimateModel({
    required this.product,
    required this.wallArea,
    required this.totalPaintingArea,
    required this.paintRequired,
    required this.suggestedPack,
    required this.estimatedCost,
    required this.variants,
  });

  factory PaintEstimateModel.fromJson(Map<String, dynamic> json) {
    final estimate = json['estimate'] ?? {};
    return PaintEstimateModel(
      product: estimate['Product'] ?? '',
      wallArea: estimate['Wall area'] ?? '',
      totalPaintingArea: estimate['Total painting area'] ?? '',
      paintRequired: estimate['Paint required'] ?? '',
      suggestedPack: estimate['Suggested pack'] ?? '',
      estimatedCost: estimate['Estimated cost'] ?? '',
      variants: (estimate['Available variants in DB'] as List? ?? [])
          .map((e) => PaintVariant.fromJson(e))
          .toList(),
    );
  }
}