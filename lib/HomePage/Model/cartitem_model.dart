// lib/models/cart_item_model.dart

class CartItemModel {
  final int id;
  final int product;
  final String productName;
  final String price;
  final String offerPrice;
  final String discountPercent;
  final String productImage;
  final String weight;
  final String category;

  const CartItemModel({
    required this.id,
    required this.product,
    required this.productName,
    required this.price,
    required this.offerPrice,
    required this.discountPercent,
    required this.productImage,
    required this.weight,
    required this.category,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      id: json['id'] as int? ?? 0,
      product: json['product'] as int? ?? 0,
      productName: json['product_name'] as String? ?? '',
      price: json['price']?.toString() ?? '0',
      offerPrice: json['offer_price']?.toString() ?? '0',
      discountPercent: json['discount_percent']?.toString() ?? '0',
      productImage: json['product_image'] as String? ?? '',
      weight: json['weight']?.toString() ?? '',
      category: json['category_name'] as String? ?? '',
    );
  }
}
