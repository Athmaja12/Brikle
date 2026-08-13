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