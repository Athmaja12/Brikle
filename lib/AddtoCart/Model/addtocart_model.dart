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
  final int materialId;
  final String materialName;
  final String sizeDimension;
  final String imageUrl;
  final int quantity;
  final double unitPriceWithGst;
  final double discountPercentage;
  final double totalPriceWithGst;

  final List<PriceTier>? _priceTiers;

  List<PriceTier> get priceTiers => _priceTiers ?? const <PriceTier>[];

  const CartItem({
    required this.id,
    required this.variantId,
    required this.materialId,
    required this.materialName,
    required this.sizeDimension,
    required this.imageUrl,
    required this.quantity,
    required this.unitPriceWithGst,
    this.discountPercentage = 0,
    required this.totalPriceWithGst,
    List<PriceTier>? priceTiers,
  }) : _priceTiers = priceTiers;

  bool get hasDiscount => discountPercentage > 0;

  /// GST-inclusive offer unit price (same formula as ProductDetails/Home/Category)
  double get discountedUnitPrice =>
      hasDiscount ? unitPriceWithGst * (1 - discountPercentage / 100) : unitPriceWithGst;

  /// Effective unit price taking into account wholesale price tiers (if active)
  /// or offer discount.
  double get effectiveUnitPrice {
    if (hasTiers && priceTiers.isNotEmpty) {
      PriceTier? applicable;
      for (final tier in priceTiers) {
        if (quantity >= tier.minQty) applicable = tier;
      }
      if (applicable != null) return applicable.price;
    }
    return discountedUnitPrice;
  }

  bool get hasTiers => priceTiers.isNotEmpty;

  double get bestTierPrice =>
      priceTiers.isEmpty ? discountedUnitPrice : priceTiers.last.price;

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

    final rawUnitPrice = (json['unit_price_with_gst'] as num?)?.toDouble() ?? 0;
    final discount = json['discount_percentage'] is num
        ? (json['discount_percentage'] as num).toDouble()
        : double.tryParse(json['discount_percentage']?.toString() ?? '0') ?? 0;
    final qty = (json['quantity'] as num?)?.toInt() ?? 0;

    double effectiveUnit = rawUnitPrice;
    if (discount > 0) {
      effectiveUnit = rawUnitPrice * (1 - discount / 100);
    }
    if (tiers.isNotEmpty && qty > 0) {
      PriceTier? applicable;
      for (final tier in tiers) {
        if (qty >= tier.minQty) applicable = tier;
      }
      if (applicable != null) effectiveUnit = applicable.price;
    }

    final calculatedTotal = effectiveUnit * qty;
    final serverTotal =
        (json['total_price_with_gst'] as num?)?.toDouble() ?? 0;

    return CartItem(
      id: json['id'] as int? ?? 0,
      variantId: json['variant'] as int? ?? 0,
      materialId: (json['material_id'] as num?)?.toInt() ?? 0,
      materialName: json['material_name']?.toString() ?? '',
      sizeDimension: json['size_dimension']?.toString() ?? '',
      imageUrl: _fullImageUrl(json['master_image']?.toString()),
      quantity: qty,
      unitPriceWithGst: rawUnitPrice,
      discountPercentage: discount,
      totalPriceWithGst:
          calculatedTotal > 0 ? calculatedTotal : serverTotal,
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
    'material_id': materialId,
    'material_name': materialName,
    'size_dimension': sizeDimension,
    'master_image': imageUrl,
    'quantity': quantity,
    'unit_price_with_gst': unitPriceWithGst,
    'discount_percentage': discountPercentage,
    'total_price_with_gst': totalPriceWithGst,
    'price_tiers': priceTiers.map((t) => t.toJson()).toList(),
  };

  CartItem copyWith({
    int? quantity,
    double? unitPriceWithGst,
    double? discountPercentage,
    double? totalPriceWithGst,
    List<PriceTier>? priceTiers,
  }) {
    final newQty = quantity ?? this.quantity;
    final newUnitPrice = unitPriceWithGst ?? this.unitPriceWithGst;
    final newDiscount = discountPercentage ?? this.discountPercentage;
    final newTiers = priceTiers ?? this.priceTiers;

    double newTotal = totalPriceWithGst ?? this.totalPriceWithGst;
    if (quantity != null ||
        unitPriceWithGst != null ||
        discountPercentage != null) {
      double effectiveUnit =
          newDiscount > 0 ? newUnitPrice * (1 - newDiscount / 100) : newUnitPrice;
      if (newTiers.isNotEmpty && newQty > 0) {
        PriceTier? applicable;
        for (final tier in newTiers) {
          if (newQty >= tier.minQty) applicable = tier;
        }
        if (applicable != null) effectiveUnit = applicable.price;
      }
      newTotal = effectiveUnit * newQty;
    }

    return CartItem(
      id: id,
      variantId: variantId,
      materialId: materialId,
      materialName: materialName,
      sizeDimension: sizeDimension,
      imageUrl: imageUrl,
      quantity: newQty,
      unitPriceWithGst: newUnitPrice,
      discountPercentage: newDiscount,
      totalPriceWithGst: newTotal,
      priceTiers: newTiers,
    );
  }
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