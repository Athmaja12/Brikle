// lib/models/product_model.dart

class ProductModel {
  final int id;
  final String name;
  final String description;
  final String price;
  final String unit;
  final String image;
  final String category;
  final double stock; // ← was int, API sends 600.0 (double)

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.unit,
    required this.image,
    required this.category,
    required this.stock,
  });

  bool get inStock => stock > 0;

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: json['price']?.toString() ?? '0',
      unit: json['unit'] as String? ?? '',
      // image can be null from API — fallback to empty string
      image: json['image'] as String? ?? '',
      // category comes as int ID, category_name is the display string
      category: json['category_name'] as String? ?? '',
      // stock comes as double (e.g. 600.0) — cast via num to be safe
      stock: (json['stock'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
