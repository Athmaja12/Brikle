// lib/Wishlist/Model/wishlist_model.dart

class WishlistModel {
  final int id; // wishlist entry id (used for delete/move-to-cart)
  final int productId; // the underlying product id
  final String productName;
  final String? productImage;
  final double price;
  final bool isActive;
  final DateTime? addedAt;

  WishlistModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.price,
    this.isActive = true,
    this.addedAt,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: json['id'] as int,
      productId: json['product'] as int,
      productName: json['product_name']?.toString() ?? '',
      productImage: json['product_image']?.toString(),
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      addedAt: json['added_at'] != null
          ? DateTime.tryParse(json['added_at'].toString())
          : null,
    );
  }
}