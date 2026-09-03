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
  final double retailPrice;   // "retail_price" comes as a String from API e.g. "100.00"
  final double priceWithGst;  // "price_with_gst" — the price to display in the UI
  final String createdAt;

  const WishlistItem({
    required this.id,
    required this.variantId,
    required this.materialId,
    required this.materialName,
    required this.sizeDimension,
    required this.imageUrl,
    required this.retailPrice,
    required this.priceWithGst,
    required this.createdAt,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: (json['id'] as num).toInt(),
        variantId: (json['variant'] as num).toInt(),
        materialId: (json['material_id'] as num).toInt(),
        materialName: json['material_name']?.toString() ?? '',
        sizeDimension: json['size_dimension']?.toString() ?? '',
        imageUrl: _fullImageUrl(json['master_image']?.toString()),
        // retail_price comes as a String e.g. "100.00" — parse safely
        retailPrice: double.tryParse(json['retail_price']?.toString() ?? '0') ?? 0,
        // price_with_gst comes as a number (e.g. 422.4) — handle either a
        // num or a stringified number defensively, same as retail_price.
        priceWithGst: json['price_with_gst'] is num
            ? (json['price_with_gst'] as num).toDouble()
            : double.tryParse(json['price_with_gst']?.toString() ?? '0') ?? 0,
        createdAt: json['created_at']?.toString() ?? '',
      );
}