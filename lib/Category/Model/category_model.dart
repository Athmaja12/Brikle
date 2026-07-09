/// Independent copy of the category shape used by Home's CategoryItem —
/// duplicated on purpose so CategoryPage doesn't depend on HomePage's model.
class CategoryGridItem {
  final int id;
  final String name;
  final String? imageUrl;

  CategoryGridItem({required this.id, required this.name, this.imageUrl});

  factory CategoryGridItem.fromJson(Map<String, dynamic> json) =>
      CategoryGridItem(
        id: json['id'] as int,
        name: json['name']?.toString() ?? '',
        imageUrl: json['image']?.toString(),
      );
}

/// Single static "Offer Zone" banner — not per-category, since this screen
/// has no selection concept (unlike Home's category-chip-driven banner).
class OfferBanner {
  final String title;
  final String subtitle;
  final String discountText;
  final String imageUrl;

  const OfferBanner({
    required this.title,
    required this.subtitle,
    required this.discountText,
    this.imageUrl = '',
  });
}

/// Same shape as Home's PromoTile — local asset + target category name.
class CategoryPromoTile {
  final String assetPath;
  final String categoryName;
  final String semanticLabel;

  const CategoryPromoTile({
    required this.assetPath,
    required this.categoryName,
    required this.semanticLabel,
  });
}
