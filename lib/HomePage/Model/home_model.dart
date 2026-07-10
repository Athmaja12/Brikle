class CarouselItem {
  final int id;
  final String imageUrl;
  final String title;
  final String description;

  CarouselItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
  });

  factory CarouselItem.fromJson(Map<String, dynamic> json) => CarouselItem(
    id: json['id'] as int,
    imageUrl: json['image']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
  );
}

class CategoryItem {
  final int id;
  final String name;
  final String? imageUrl;

  CategoryItem({required this.id, required this.name, this.imageUrl});

  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
    id: json['id'] as int,
    name: json['name']?.toString() ?? '',
    imageUrl: json['image']?.toString(),
  );
}

/// "Top Deals of the Week" — /api/deals-of-the-week/
/// Nested shape: { variant_details: { material: {...}, retail_price_with_gst }, deal_retail_price_with_gst, discount_percentage }
class DealItem {
  final int dealId;
  final int variantId;
  final int materialId;
  final String name;
  final String imageUrl;
  final double retailPrice;
  final double dealPrice;
  final int discountPercent;
  final String? customTitle;

  const DealItem({
    required this.dealId,
    required this.variantId,
    required this.materialId,
    required this.name,
    required this.imageUrl,
    required this.retailPrice,
    required this.dealPrice,
    required this.discountPercent,
    this.customTitle,
  });

  factory DealItem.fromJson(Map<String, dynamic> json) {
    final variant = json['variant_details'] as Map<String, dynamic>? ?? {};
    final material = variant['material'] as Map<String, dynamic>? ?? {};

    double _toDouble(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0;
    }

    return DealItem(
      dealId: json['id'] as int? ?? 0,
      variantId: variant['id'] as int? ?? 0,
      materialId: material['id'] as int? ?? 0,
      name: material['name']?.toString() ?? '',
      imageUrl: material['master_image']?.toString() ?? '',
      retailPrice: _toDouble(variant['retail_price_with_gst']),
      dealPrice: _toDouble(json['deal_retail_price_with_gst']),
      discountPercent: (json['discount_percentage'] as num?)?.toInt() ?? 0,
      customTitle: json['custom_title']?.toString(),
    );
  }
}

/// "Bestselling on [Category]" — /api/best-selling/?category_id={id}
/// NOTE: this endpoint returns no price/variant data — name + image only,
/// per confirmed product decision. Do not add price fields here unless the
/// backend response actually changes to include a variant.
class BestSellingItem {
  final int id;
  final String name;
  final String? imageUrl;
  final double? retailPrice;
  final double? dealPrice;
  final int? discountPercent;

  const BestSellingItem({
    required this.id,
    required this.name,
    this.imageUrl,
    this.retailPrice,
    this.dealPrice,
    this.discountPercent,
  });

  factory BestSellingItem.fromJson(Map<String, dynamic> json) {
    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return BestSellingItem(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      imageUrl: json['master_image']?.toString(),
      // TODO: field names below are guesses — confirm against the updated
      // backend response and adjust the keys once resent.
      retailPrice: toDouble(json['retail_price_with_gst']),
      dealPrice: toDouble(
        json['deal_retail_price_with_gst'] ?? json['selling_price'],
      ),
      discountPercent: (json['discount_percentage'] as num?)?.toInt(),
    );
  }
}

class PromoTile {
  final String assetPath; // local asset, e.g. 'assets/images/promo_tools.png'
  final String
  categoryName; // must match CategoryItem.name from the API exactly
  final String
  semanticLabel; // for screen readers, since the image has no live text

  const PromoTile({
    required this.assetPath,
    required this.categoryName,
    required this.semanticLabel,
  });
}
