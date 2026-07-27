class SearchResultItem {
  final int variantId;
  final int materialId;
  final String productName;
  final String brandName;
  final String categoryName;
  final String subcategoryName;
  final String sizeDimension;
  final String retailPrice;
  final String? masterImage;

  const SearchResultItem({
    required this.variantId,
    required this.materialId,
    required this.productName,
    required this.brandName,
    required this.categoryName,
    required this.subcategoryName,
    required this.sizeDimension,
    required this.retailPrice,
    this.masterImage,
  });

  factory SearchResultItem.fromJson(Map<String, dynamic> json) {
    return SearchResultItem(
      variantId: json['variant_id'] as int? ?? 0,
      materialId: json['material_id'] as int? ?? 0,
      productName: json['product_name']?.toString() ?? '',
      brandName: json['brand_name']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      subcategoryName: json['subcategory_name']?.toString() ?? '',
      sizeDimension: json['size_dimension']?.toString() ?? '',
      retailPrice: json['retail_price']?.toString() ?? '0.00',
      masterImage: json['master_image']?.toString(),
    );
  }
}