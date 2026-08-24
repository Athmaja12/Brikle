// lib/HomePage/Model/banner_model.dart

class BannerModel {
  final int id;
  final String image;   // relative path: /media/carousel/xxx.jpg
  final String title;
  final bool isActive;
  final int displayOrder;
  final int? category;
  final String? categoryName;
  final int? material;
  final String? materialName;

  const BannerModel({
    required this.id,
    required this.image,
    required this.title,
    required this.isActive,
    required this.displayOrder,
    this.category,
    this.categoryName,
    this.material,
    this.materialName,
  });

  /// Full image URL — base is injected from ApiConfig.baseUrl
  String imageUrl(String baseUrl) {
    if (image.isEmpty) return '';
    if (image.startsWith('http')) return image;          // already absolute
    return '$baseUrl$image';                              // e.g. http://192.168.1.33:8000/media/carousel/bug2.jpeg
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return BannerModel(
      id:           toInt(json['id'])            ?? 0,
      image:        json['image']         as String? ?? '',
      title:        json['title']         as String? ?? '',
      isActive:     json['is_active']     as bool?   ?? false,
      displayOrder: toInt(json['display_order']) ?? 0,
      category:     toInt(json['category']),
      categoryName: json['category_name'] as String?,
      material:     toInt(json['material']),
      materialName: json['material_name'] as String?,
    );
  }
}