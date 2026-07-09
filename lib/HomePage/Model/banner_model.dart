// lib/HomePage/Model/banner_model.dart

class BannerModel {
  final int id;
  final String image;   // relative path: /media/carousel/xxx.jpg
  final String title;
  final bool isActive;
  final int displayOrder;

  const BannerModel({
    required this.id,
    required this.image,
    required this.title,
    required this.isActive,
    required this.displayOrder,
  });

  /// Full image URL — base is injected from ApiConfig.baseUrl
  String imageUrl(String baseUrl) {
    if (image.isEmpty) return '';
    if (image.startsWith('http')) return image;          // already absolute
    return '$baseUrl$image';                              // e.g. http://192.168.1.33:8000/media/carousel/bug2.jpeg
  }

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id:           json['id']            as int?    ?? 0,
      image:        json['image']         as String? ?? '',
      title:        json['title']         as String? ?? '',
      isActive:     json['is_active']     as bool?   ?? false,
      displayOrder: json['display_order'] as int?    ?? 0,
    );
  }
}