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

  // FIX: stored as nullable internally so ANY runtime null (from JSON
  // dynamic values slipping through the type system) is caught by the
  // getter instead of crashing the widget tree.
  final List<PriceTier>? _priceTiers;

  // Public getter always returns a non-null list — the widget never
  // needs to handle null, and the stored field being null is safe.
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
    List<PriceTier>?
    priceTiers, // nullable param — null and [] are both "no tiers"
  }) : _priceTiers = priceTiers;

  // Derived helpers
  bool get hasTiers => priceTiers.isNotEmpty;

  double get bestTierPrice =>
      priceTiers.isEmpty ? unitPriceWithGst : priceTiers.last.price;

  int get bestTierMinQty => priceTiers.isEmpty ? 1 : priceTiers.last.minQty;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Build tier list defensively — handles null, wrong type, and empty
    final raw = json['price_tiers'];
    final List<PriceTier> tiers;
    if (raw == null || raw is! List || raw.isEmpty) {
      tiers = const <PriceTier>[]; // FIX: explicit type param, not const []
    } else {
      tiers = raw
          .whereType<Map<String, dynamic>>() // skip any malformed elements
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
    // preserve existing tiers through qty updates — priceTiers param
    // is nullable so passing null here uses _priceTiers fallback in getter
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
