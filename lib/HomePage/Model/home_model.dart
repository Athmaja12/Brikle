import 'package:brikle/ApiConfiguration/apiconfig.dart';
import 'package:flutter/material.dart';

String _fullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${ApiConfig.baseUrl}$path';
}

class CarouselItem {
  final int id;
  final String imageUrl;
  final String title;
  final String description;

  CarouselItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
  });

  factory CarouselItem.fromJson(Map<String, dynamic> json) => CarouselItem(
    id: json['id'] as int,
    imageUrl: _fullImageUrl(json['image']),
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
  );
}

class CategoryItem {
  final int id;
  final String name;
  final String? imageUrl;

  CategoryItem({required this.id, required this.name, this.imageUrl});

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
    id: json['id'] as int,
    name: json['name']?.toString() ?? '',
    imageUrl: _fullImageUrl(json['image']?.toString()),
  );
}

/// "Top Deals of the Week" — /api/deals-of-the-week/
/// Nested shape: { variant_details: { material: {...}, retail_price_with_gst }, deal_retail_price_with_gst, discount_percentage }
class DealItem {
  final int dealId;
  final int variantId;
  final int materialId;
  final String name;
  final String imageUrl;
  final double retailPrice;
  final double dealPrice;
  final int discountPercent;
  final String? customTitle;
  final DateTime? endDate; // NEW
  final bool isExpired; // NEW

  const DealItem({
    required this.dealId,
    required this.variantId,
    required this.materialId,
    required this.name,
    required this.imageUrl,
    required this.retailPrice,
    required this.dealPrice,
    required this.discountPercent,
    this.customTitle,
    this.endDate, // NEW
    this.isExpired = false, // NEW
  });

  factory DealItem.fromJson(Map<String, dynamic> json) {
    final variant = json['variant_details'] as Map<String, dynamic>? ?? {};
    final material = variant['material'] as Map<String, dynamic>? ?? {};

    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    DateTime? _toDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return DealItem(
      dealId: json['id'] as int? ?? 0,
      variantId: variant['id'] as int? ?? 0,
      materialId: material['id'] as int? ?? 0,
      name: material['name']?.toString() ?? '',
      imageUrl: _fullImageUrl(
        json['image']?.toString() ?? material['master_image']?.toString(),
      ),
      retailPrice: _toDouble(variant['retail_price_with_gst']),
      dealPrice: _toDouble(json['deal_retail_price_with_gst']),
      discountPercent: (json['discount_percentage'] as num?)?.toInt() ?? 0,
      customTitle: json['custom_title']?.toString(),
      endDate: _toDate(json['end_date']), // NEW
      isExpired: json['is_expired'] == true, // NEW
    );
  }
}

/// "Bestselling on [Category]" — /api/best-selling/?category_id={id}
/// NOTE: this endpoint returns no price/variant data — name + image only,
/// per confirmed product decision. Do not add price fields here unless the
/// backend response actually changes to include a variant.
class BestSellingItem {
  final int id;
  final String name;
  final String? description;
  final String? productHighlights;
  final String imageUrl; // master_image, falling back to images[0].image
  final String? brandName;
  final String? categoryName;
  final String? subcategoryName;
  final double retailPrice;
  final bool isBestSelling;

  // Optional — only non-null if the backend actually sends offer data.
  final int? discountPercent;
  final double? dealPrice;

  const BestSellingItem({
    required this.id,
    required this.name,
    this.description,
    this.productHighlights,
    required this.imageUrl,
    this.brandName,
    this.categoryName,
    this.subcategoryName,
    required this.retailPrice,
    this.isBestSelling = false,
    this.discountPercent,
    this.dealPrice,
  });

  /// True only when the backend actually provided BOTH a positive
  /// discount percent AND a deal price — used to decide whether the UI
  /// shows the offer badge / strikethrough / deal price at all.
  bool get hasOffer =>
      discountPercent != null && discountPercent! > 0 && dealPrice != null;

  factory BestSellingItem.fromJson(Map<String, dynamic> json) {
    double toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    double? toDoubleOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? toIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final brand = json['brand'] as Map<String, dynamic>?;
    final subcategory = json['subcategory'] as Map<String, dynamic>?;
    final category = subcategory?['category'] as Map<String, dynamic>?;

    // ── Image fallback chain ────────────────────────────────────────
    // 1. master_image, if present and non-empty
    // 2. first entry in images[], if the gallery has anything
    // 3. '' — the view's _isValidImageUrl guard turns this into the
    //    neutral icon fallback, same as any other missing image.
    final masterImage = json['master_image']?.toString();
    String? resolvedRawImage = (masterImage != null && masterImage.isNotEmpty)
        ? masterImage
        : null;

    if (resolvedRawImage == null) {
      final imagesList = json['images'] as List? ?? [];
      if (imagesList.isNotEmpty) {
        final firstImage = imagesList.first as Map<String, dynamic>?;
        final galleryPath = firstImage?['image']?.toString();
        if (galleryPath != null && galleryPath.isNotEmpty) {
          resolvedRawImage = galleryPath;
        }
      }
    }

    return BestSellingItem(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      productHighlights: json['product_highlights']?.toString(),
      imageUrl: _fullImageUrl(resolvedRawImage),
      brandName: brand?['name']?.toString(),
      categoryName: category?['name']?.toString(),
      subcategoryName: subcategory?['name']?.toString(),
      retailPrice: toDouble(json['retail_price']),
      isBestSelling: json['is_best_selling'] == true,
      discountPercent: toIntOrNull(
        json['discount_percentage'] ?? json['discount_percent'],
      ),
      dealPrice: toDoubleOrNull(
        json['deal_price'] ?? json['offer_price'] ?? json['special_price'],
      ),
    );
  }
}

class PromoTile {
  final String assetPath; // local asset, e.g. 'assets/images/promo_tools.png'
  final String
  categoryName; // must match CategoryItem.name from the API exactly
  final String
  semanticLabel; // for screen readers, since the image has no live text

  const PromoTile({
    required this.assetPath,
    required this.categoryName,
    required this.semanticLabel,
  });
}
