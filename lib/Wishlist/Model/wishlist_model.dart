import 'package:brikle/ApiConfiguration/apiconfig.dart';

String _fullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final base = ApiConfig.baseUrl;
  if (base.isEmpty) return '';
  return '$base$path';
}

class WishlistItem {
  final int id;           // wishlist entry id — used for DELETE /api/wishlist/{id}/
  final int variantId;    // "variant" in JSON
  final int materialId;   // "material_id" in JSON — required by product-details API
  final String materialName;
  final String sizeDimension;
  final String imageUrl;
  final double retailPrice;         // "retail_price" — pre-GST base, NEVER shown or discounted directly
  final double retailPriceWithGst;  // "retail_price_with_gst" — correct base for discount & display
  final double discountPercentage;  // "discount_percentage" — applied ONCE, on top of GST price
  final String createdAt;

  const WishlistItem({
    required this.id,
    required this.variantId,
    required this.materialId,
    required this.materialName,
    required this.sizeDimension,
    required this.imageUrl,
    required this.retailPrice,
    required this.retailPriceWithGst,
    required this.discountPercentage,
    required this.createdAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: (json['id'] as num).toInt(),
        variantId: (json['variant'] as num).toInt(),
        materialId: (json['material_id'] as num).toInt(),
        materialName: json['material_name']?.toString() ?? '',
        sizeDimension: json['size_dimension']?.toString() ?? '',
        imageUrl: _fullImageUrl(json['master_image']?.toString()),
        // retail_price comes as a String e.g. "100.00"
        retailPrice:
            double.tryParse(json['retail_price']?.toString() ?? '0') ?? 0,
        // retail_price_with_gst comes as a number e.g. 118.00 — handle
        // either a num or a stringified number defensively.
        retailPriceWithGst: json['retail_price_with_gst'] is num
            ? (json['retail_price_with_gst'] as num).toDouble()
            : double.tryParse(
                    json['retail_price_with_gst']?.toString() ?? '0') ??
                0,
        // discount_percentage comes as a number e.g. 10 (or 0 / absent
        // when there's no active offer) — same defensive parsing.
        discountPercentage: json['discount_percentage'] is num
            ? (json['discount_percentage'] as num).toDouble()
            : double.tryParse(
                    json['discount_percentage']?.toString() ?? '0') ??
                0,
        createdAt: json['created_at']?.toString() ?? '',
      );

  bool get hasDiscount => discountPercentage > 0;

  /// Same formula as ProductDetailController.discountedPrice, but applied
  /// to the GST-inclusive price (never retailPrice) and computed exactly
  /// once — this is the ONLY price this screen should ever display.
  double get finalPrice {
    if (!hasDiscount) return retailPriceWithGst;
    return retailPriceWithGst * (1 - discountPercentage / 100);
  }
}