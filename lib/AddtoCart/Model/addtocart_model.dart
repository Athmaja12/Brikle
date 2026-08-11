import 'package:brikle/ApiConfiguration/apiconfig.dart';

String _fullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  final base = ApiConfig.baseUrl;
  if (base.isEmpty) return '';
  return '$base$path';
}

class PriceTier {
  final int minQty;
  final double price;

  const PriceTier({required this.minQty, required this.price});

  factory PriceTier.fromJson(Map<String, dynamic> json) => PriceTier(
    minQty: (json['min_qty'] as num?)?.toInt() ?? 0,
    price: (json['price'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'min_qty': minQty,
    'price': price,
  };
}

class CartItem {
  final int id;
  final int variantId;
  final String materialName;
  final String sizeDimension;
  final String imageUrl;
  final int quantity;
  final double unitPriceWithGst;
  final double totalPriceWithGst;

  final List<PriceTier>? _priceTiers;

  List<PriceTier> get priceTiers => _priceTiers ?? const <PriceTier>[];

  const CartItem({
    required this.id,
    required this.variantId,
    required this.materialName,
    required this.sizeDimension,
    required this.imageUrl,
    required this.quantity,
    required this.unitPriceWithGst,
    required this.totalPriceWithGst,
    List<PriceTier>? priceTiers,
  }) : _priceTiers = priceTiers;

  bool get hasTiers => priceTiers.isNotEmpty;

  double get bestTierPrice =>
      priceTiers.isEmpty ? unitPriceWithGst : priceTiers.last.price;

  int get bestTierMinQty => priceTiers.isEmpty ? 1 : priceTiers.last.minQty;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final raw = json['price_tiers'];
    final List<PriceTier> tiers;
    if (raw == null || raw is! List || raw.isEmpty) {
      tiers = const <PriceTier>[];
    } else {
      tiers = raw
          .whereType<Map<String, dynamic>>()
          .map(PriceTier.fromJson)
          .toList();
    }

    return CartItem(
      id: json['id'] as int,
      variantId: json['variant'] as int,
      materialName: json['material_name']?.toString() ?? '',
      sizeDimension: json['size_dimension']?.toString() ?? '',
      imageUrl: _fullImageUrl(json['master_image']?.toString()),
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      unitPriceWithGst: (json['unit_price_with_gst'] as num?)?.toDouble() ?? 0,
      totalPriceWithGst:
          (json['total_price_with_gst'] as num?)?.toDouble() ?? 0,
      priceTiers: tiers,
    );
  }

  /// Used for guest-cart local persistence (GuestCartService) and for
  /// pushing a guest item to the server cart. `master_image` is stored
  /// as the already-resolved absolute URL — safe to round-trip through
  /// fromJson since _fullImageUrl() passes through anything starting
  /// with "http" unchanged.
  Map<String, dynamic> toJson() => {
    'id': id,
    'variant': variantId,
    'material_name': materialName,
    'size_dimension': sizeDimension,
    'master_image': imageUrl,
    'quantity': quantity,
    'unit_price_with_gst': unitPriceWithGst,
    'total_price_with_gst': totalPriceWithGst,
    'price_tiers': priceTiers.map((t) => t.toJson()).toList(),
  };

  CartItem copyWith({
    int? quantity,
    double? unitPriceWithGst,
    double? totalPriceWithGst,
    List<PriceTier>? priceTiers,
  }) => CartItem(
    id: id,
    variantId: variantId,
    materialName: materialName,
    sizeDimension: sizeDimension,
    imageUrl: imageUrl,
    quantity: quantity ?? this.quantity,
    unitPriceWithGst: unitPriceWithGst ?? this.unitPriceWithGst,
    totalPriceWithGst: totalPriceWithGst ?? this.totalPriceWithGst,
    priceTiers: priceTiers ?? this.priceTiers,
  );
}

class CartResponse {
  final double grandTotalWithGst;
  final List<CartItem> items;

  const CartResponse({required this.grandTotalWithGst, required this.items});

  factory CartResponse.fromJson(Map<String, dynamic> json) => CartResponse(
    grandTotalWithGst: (json['grand_total_with_gst'] as num?)?.toDouble() ?? 0,
    items: (json['cart_items'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CartItem.fromJson)
        .toList(),
  );
}