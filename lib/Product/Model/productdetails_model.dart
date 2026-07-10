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

/// Full material details — /api/superadmin/materials/{id}/
/// NOTE: this endpoint has no price/variant data by design. Pricing for
/// the detail screen comes from the CategoryProductItem the user tapped
/// (already fetched on the Category Products screen), not from here.
class MaterialDetail {
  final int id;
  final String name;
  final String description;
  final String productHighlights;
  final String masterImage;
  final List<String> galleryImages;
  final List<MaterialFaq> faqs;
  final String? brandName;
  final String? categoryName;
  final String? subcategoryName;

  const MaterialDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.productHighlights,
    required this.masterImage,
    required this.galleryImages,
    required this.faqs,
    this.brandName,
    this.categoryName,
    this.subcategoryName,
  });

  factory MaterialDetail.fromJson(Map<String, dynamic> json) {
    final subcategory = json['subcategory'] as Map<String, dynamic>?;
    final category = subcategory?['category'] as Map<String, dynamic>?;
    final brand = json['brand'] as Map<String, dynamic>?;
    final images = json['images'] as List? ?? [];
    final faqs = json['faqs'] as List? ?? [];

    return MaterialDetail(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      productHighlights: json['product_highlights']?.toString() ?? '',
      masterImage: _fullImageUrl(json['master_image']?.toString()),
      galleryImages: images
          .map((e) => _fullImageUrl((e as Map<String, dynamic>)['image']?.toString()))
          .where((url) => url.isNotEmpty)
          .toList(),
      faqs: faqs.map((e) => MaterialFaq.fromJson(e as Map<String, dynamic>)).toList(),
      brandName: brand?['name']?.toString(),
      categoryName: category?['name']?.toString(),
      subcategoryName: subcategory?['name']?.toString(),
    );
  }
}