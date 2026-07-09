// lib/Cart/Model/cart_model.dart

class CartItemModel {
  final int id;
  final int product;
  final String productName;
  final String price;
  final String offerPrice;
  final String discountPercent;
  final String? productImage;
  final int weight;       // mapped from API field "amount"
  final String unitType;  // mapped from API field "unit_type"
  final int categoryId;   // extracted from nested category object

  CartItemModel({
    required this.id,
    required this.product,
    required this.productName,
    required this.price,
    required this.offerPrice,
    required this.discountPercent,
    this.productImage,
    required this.weight,
    required this.unitType,
    required this.categoryId,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    // "amount" comes as a string like "500.00" — parse to int
    final rawAmount = json['amount'];
    final weight = rawAmount != null
        ? double.tryParse(rawAmount.toString())?.toInt() ?? 0
        : 0;

    // "category" is a nested object — extract just the id
    final categoryRaw = json['category'];
    final categoryId = categoryRaw is Map ? (categoryRaw['id'] as int? ?? 0) : 0;

    return CartItemModel(
      id: json['id'] as int,
      product: json['product'] as int,
      productName: json['product_name']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      offerPrice: json['offer_price']?.toString() ?? '0',
      discountPercent: json['discount_percent']?.toString() ?? '0',
      productImage: json['product_image']?.toString(),
      weight: weight,
      unitType: json['unit_type']?.toString() ?? '',
      categoryId: categoryId,
    );
  }

  CartItemModel copyWith({int? weight}) {
    return CartItemModel(
      id: id,
      product: product,
      productName: productName,
      price: price,
      offerPrice: offerPrice,
      discountPercent: discountPercent,
      productImage: productImage,
      weight: weight ?? this.weight,
      unitType: unitType,
      categoryId: categoryId,
    );
  }

}

class AddressModel {
  final int id;
  final String addressLine;
  final bool isPrimary;

  AddressModel({ 
    required this.id,
    required this.addressLine,
    required this.isPrimary,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'],
      addressLine: json['address_line'] ?? '',
      isPrimary: json['is_primary'] ?? false,
    );
  }
}