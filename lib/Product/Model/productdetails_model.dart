// lib/Product/Model/productdetails_model.dart

import 'package:brikle/ApiConfiguration/apiconfig.dart';

String _fullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return '${ApiConfig.baseUrl}$path';
}

class MaterialFaq {
  final int id;
  final String question;
  final String answer;

  MaterialFaq({required this.id, required this.question, required this.answer});

  factory MaterialFaq.fromJson(Map<String, dynamic> json) => MaterialFaq(
    id: json['id'] as int,
    question: json['question']?.toString() ?? '',
    answer: json['answer']?.toString() ?? '',
  );
}

class SmartSuggestion {
  final int id;
  final String name;
  final String imageUrl;
  final String brandName;
  final bool isBestSelling;

  SmartSuggestion({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.brandName,
    required this.isBestSelling,
  });

  factory SmartSuggestion.fromJson(Map<String, dynamic> json) {
    return SmartSuggestion(
      id: json['id'],
      name: json['name'] ?? '',
      imageUrl: _fullImageUrl(json['master_image_url']),
      brandName: json['brand_name'] ?? '',
      isBestSelling: json['is_best_selling'] ?? false,
    );
  }
}

// NEW: Offer model
class ProductOffer {
  final double discountPercentage;
  final int dealId;

  const ProductOffer({
    required this.discountPercentage,
    required this.dealId,
  });

  factory ProductOffer.fromJson(Map<String, dynamic> json) => ProductOffer(
    discountPercentage: (json['discount_percentage'] as num?)?.toDouble() ?? 0,
    dealId: (json['deal_id'] as num?)?.toInt() ?? 0,
  );

  String get label => '${discountPercentage.toInt()}% Off';
}

/// Full material details — /api/superadmin/materials/{id}/
class MaterialDetail {
  final int id;
  final String name;
  final String description;
  final String productHighlights;
  final String masterImage;
  final List<String> galleryImages;
  final List<MaterialFaq> faqs;
  final String? brandName;
  final int? categoryId;
  final String? categoryName;
  final String? subcategoryName;
  final ProductOffer? offer; // NEW: Add offer

  const MaterialDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.productHighlights,
    required this.masterImage,
    required this.galleryImages,
    required this.faqs,
    this.brandName,
    this.categoryId,
    this.categoryName,
    this.subcategoryName,
    this.offer, // NEW
  });

  factory MaterialDetail.fromJson(Map<String, dynamic> json) {
    final subcategory = json['subcategory'] as Map<String, dynamic>?;
    final category = subcategory?['category'] as Map<String, dynamic>?;
    final brand = json['brand'] as Map<String, dynamic>?;
    final images = json['images'] as List? ?? [];
    final faqs = json['faqs'] as List? ?? [];
    final offerJson = json['offer'] as Map<String, dynamic>?;

    return MaterialDetail(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      productHighlights: json['product_highlights']?.toString() ?? '',
      masterImage: _fullImageUrl(json['master_image']?.toString()),
      galleryImages: images
          .map(
            (e) =>
                _fullImageUrl((e as Map<String, dynamic>)['image']?.toString()),
          )
          .where((url) => url.isNotEmpty)
          .toList(),
      faqs: faqs
          .map((e) => MaterialFaq.fromJson(e as Map<String, dynamic>))
          .toList(),
      brandName: brand?['name']?.toString(),
      categoryId: category?['id'] as int?,
      categoryName: category?['name']?.toString(),
      subcategoryName: subcategory?['name']?.toString(),
      offer: offerJson != null ? ProductOffer.fromJson(offerJson) : null, // NEW
    );
  }

}

double _toDouble(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0.0;
}

class CombinedTier {
  final int minQty;
  final double priceWithGst;

  const CombinedTier({required this.minQty, required this.priceWithGst});
}

class CombinedSuggestionVariant {
  final int id;
  final String sizeDimension;
  final String thicknessOrSpec;
  final String sku;
  final int stock;
  final bool isActive;
  final double retailPrice;
  final double retailPriceWithGst;
  final List<CombinedTier> tiers;

  const CombinedSuggestionVariant({
    required this.id,
    required this.sizeDimension,
    required this.thicknessOrSpec,
    required this.sku,
    required this.stock,
    required this.isActive,
    required this.retailPrice,
    required this.retailPriceWithGst,
    required this.tiers,
  });

  factory CombinedSuggestionVariant.fromJson(Map<String, dynamic> json) {
    final tiers = <CombinedTier>[];
    for (final n in [1, 2, 3]) {
      final minQty = json['tier_${n}_min_qty'];
      final price = json['tier_${n}_price_with_gst'];
      // Skip tiers the backend sent as null (see tier_2/tier_3 in the
      // ACC OPC Cement example — null minQty means "no such tier").
      if (minQty == null || price == null) continue;
      final parsedQty = (minQty is num) ? minQty.toInt() : int.tryParse(minQty.toString());
      if (parsedQty == null) continue;
      tiers.add(CombinedTier(minQty: parsedQty, priceWithGst: _toDouble(price)));
    }

    return CombinedSuggestionVariant(
      id: json['id'] as int,
      sizeDimension: json['size_dimension']?.toString() ?? '',
      thicknessOrSpec: json['thickness_or_spec']?.toString() ?? '',
      sku: json['sku']?.toString() ?? '',
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      retailPrice: _toDouble(json['retail_price']),
      retailPriceWithGst: _toDouble(json['retail_price_with_gst']),
      tiers: tiers,
    );
  }
}

class CombinedSuggestionItem {
  final int materialId;
  final String name;
  final String brandName;
  final String imageUrl;
  final bool isBestSelling;
  final List<CombinedSuggestionVariant> variants;

  const CombinedSuggestionItem({
    required this.materialId,
    required this.name,
    required this.brandName,
    required this.imageUrl,
    required this.isBestSelling,
    required this.variants,
  });

  /// The variant shown on the card / used when the card is tapped.
  /// Picks the first *active* variant, falling back to the first variant
  /// at all so a fully-inactive material still opens something.
  CombinedSuggestionVariant? get defaultVariant {
    if (variants.isEmpty) return null;
    return variants.firstWhere((v) => v.isActive, orElse: () => variants.first);
  }

  factory CombinedSuggestionItem.fromJson(Map<String, dynamic> json) {
    final variantsJson = json['variants'] as List? ?? [];
    return CombinedSuggestionItem(
      materialId: json['id'] as int,
      name: json['name']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? '',
      imageUrl: _fullImageUrl(json['master_image_url']?.toString()),
      isBestSelling: json['is_best_selling'] as bool? ?? false,
      variants: variantsJson
          .map((e) => CombinedSuggestionVariant.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CombinedSuggestionResponse {
  final int primaryProductId;
  final String primaryProductName;
  final List<CombinedSuggestionItem> suggestions;

  const CombinedSuggestionResponse({
    required this.primaryProductId,
    required this.primaryProductName,
    required this.suggestions,
  });

  factory CombinedSuggestionResponse.fromJson(Map<String, dynamic> json) {
    final list = json['combined_suggestions'] as List? ?? [];
    return CombinedSuggestionResponse(
      primaryProductId: (json['primary_product_id'] as num?)?.toInt() ?? 0,
      primaryProductName: json['primary_product_name']?.toString() ?? '',
      suggestions: list
          .map((e) => CombinedSuggestionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
