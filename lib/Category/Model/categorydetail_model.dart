import 'package:brikle/ApiConfiguration/apiconfig.dart';

String _fullImageUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  final base = ApiConfig.baseUrl;
  if (base.isEmpty) return ''; // avoid building a hostless URI
  return '$base$path';
}

String? _fullCertUrl(dynamic raw) {
  final path = raw?.toString();
  if (path == null || path.isEmpty) return null;
  return _fullImageUrl(path);
}

class PriceTier {
  final String name;
  final int minQty;
  final double price; // unit price at this tier, GST-inclusive

  const PriceTier({
    required this.name,
    required this.minQty,
    required this.price,
  });

  factory PriceTier.fromJson(Map<String, dynamic> json) => PriceTier(
    name: json['name']?.toString() ?? '',
    minQty: (json['min_qty'] as num?)?.toInt() ?? 0,
    price: (json['price'] as num?)?.toDouble() ?? 0,
  );
}

/// One purchasable product card — flattened from
/// category → subcategories → materials → variants.
/// Materials with an empty `variants` list are skipped entirely
/// (no variant = no price = nothing to show as a product card).
class CategoryProductItem {
  final int variantId;
  final int materialId;
  final String name;
  final String imageUrl;
  final String? brandName;
  final int? brandId;
  final String? type; // thickness_or_spec
  final String? quantity; // size_dimension
  final double price; // retail_price_with_gst — base unit price (qty 1)

  final bool hasTiers;
  final List<PriceTier> priceTiers; // sorted ascending by minQty

  final bool isAssured; // NEW
  final String? assuredCertificate;

  const CategoryProductItem({
    required this.variantId,
    required this.materialId,
    required this.name,
    required this.imageUrl,
    this.brandName,
    this.brandId,
    this.type,
    this.quantity,
    required this.price,
    this.hasTiers = false,
    this.priceTiers = const [],
    this.isAssured = false, // NEW
    this.assuredCertificate,
  });

  /// Effective unit price for a given quantity — picks the highest tier
  /// whose min_qty is met, falling back to the base retail price.
  double unitPriceForQuantity(int quantity) {
    if (!hasTiers || priceTiers.isEmpty) return price;
    PriceTier? applicable;
    for (final tier in priceTiers) {
      if (quantity >= tier.minQty) applicable = tier;
    }
    return applicable?.price ?? price;
  }

  /// Cheapest per-unit price achievable across all tiers — used for the
  /// "Unlock Bulk Prices of ₹X" hint under the price.
  double get bestTierPrice {
    if (priceTiers.isEmpty) return price;
    return priceTiers.map((t) => t.price).reduce((a, b) => a < b ? a : b);
  }

  factory CategoryProductItem.fromVariantJson({
    required Map<String, dynamic> variant,
    required Map<String, dynamic> fallbackMaterial,
  }) {
    final variantMaterial =
        variant['material'] as Map<String, dynamic>? ?? fallbackMaterial;
    final brand = variantMaterial['brand'] as Map<String, dynamic>?;

    final tiersJson = variant['price_tiers'] as List? ?? [];
    final tiers =
        tiersJson
            .map((t) => PriceTier.fromJson(t as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => a.minQty.compareTo(b.minQty));

    return CategoryProductItem(
      variantId: variant['id'] as int,
      materialId: fallbackMaterial['id'] as int,
      name:
          variantMaterial['name']?.toString() ??
          fallbackMaterial['name']?.toString() ??
          '',
      imageUrl: _fullImageUrl(
        variantMaterial['master_image']?.toString() ??
            fallbackMaterial['master_image']?.toString(),
      ),
      brandName: brand?['name']?.toString(),
      brandId: brand?['id'] as int?,
      type: variant['thickness_or_spec']?.toString(),
      quantity: variant['size_dimension']?.toString(),
      price: (variant['retail_price_with_gst'] as num?)?.toDouble() ?? 0,
      hasTiers: variant['has_tiers'] == true,
      priceTiers: tiers,
      isAssured:
          (variantMaterial['is_assured'] ?? fallbackMaterial['is_assured']) ==
          true, // NEW
      assuredCertificate: _fullCertUrl(
        // NEW
        variantMaterial['assured_certificate'] ??
            fallbackMaterial['assured_certificate'],
      ),
    );
  }
}

class CategoryDetail {
  final int id;
  final String name;
  final String description;
  final List<CategoryProductItem> products;

  const CategoryDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.products,
  });

  factory CategoryDetail.fromJson(Map<String, dynamic> json) {
    final products = <CategoryProductItem>[];

    final subcategories = json['subcategories'] as List? ?? [];
    for (final sub in subcategories) {
      final materials =
          (sub as Map<String, dynamic>)['materials'] as List? ?? [];
      for (final mat in materials) {
        final material = mat as Map<String, dynamic>;
        final variants = material['variants'] as List? ?? [];
        if (variants.isEmpty) continue; // no price data — skip

        for (final v in variants) {
          final variant = v as Map<String, dynamic>;
          products.add(
            CategoryProductItem.fromVariantJson(
              variant: variant,
              fallbackMaterial: material,
            ),
          );
        }
      }
    }

    return CategoryDetail(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      products: products,
    );
  }
}

class FilterCategoryOption {
  final int id;
  final String name;
  final String? imageUrl;

  FilterCategoryOption({required this.id, required this.name, this.imageUrl});

  factory FilterCategoryOption.fromJson(Map<String, dynamic> json) =>
      FilterCategoryOption(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        imageUrl: json['image']?.toString(),
      );
}

class FilterBrandOption {
  final int id;
  final String name;

  FilterBrandOption({required this.id, required this.name});

  factory FilterBrandOption.fromJson(Map<String, dynamic> json) =>
      FilterBrandOption(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
      );
}

class CategoryFilterOptions {
  final List<FilterCategoryOption> categories;
  final List<FilterBrandOption> brands;
  final List<String> types;
  final List<String> quantities;
  final double minPrice;
  final double maxPrice;

  const CategoryFilterOptions({
    required this.categories,
    required this.brands,
    required this.types,
    required this.quantities,
    required this.minPrice,
    required this.maxPrice,
  });

  factory CategoryFilterOptions.fromJson(Map<String, dynamic> json) {
    final priceRange = json['price_range'] as Map<String, dynamic>? ?? {};
    return CategoryFilterOptions(
      categories: (json['categories'] as List? ?? [])
          .map((e) => FilterCategoryOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      brands: (json['brands'] as List? ?? [])
          .map((e) => FilterBrandOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      types: (json['types'] as List? ?? []).map((e) => e.toString()).toList(),
      quantities: (json['quantities'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
      minPrice: (priceRange['min_price'] as num?)?.toDouble() ?? 0,
      maxPrice: (priceRange['max_price'] as num?)?.toDouble() ?? 0,
    );
  }
}
