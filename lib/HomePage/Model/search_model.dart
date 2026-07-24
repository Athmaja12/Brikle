// import 'package:brikle/ApiConfiguration/apiconfig.dart';

// String _fullImageUrl(String? path) {
//   if (path == null || path.isEmpty) return '';
//   if (path.startsWith('http')) return path;
//   return '${ApiConfig.baseUrl}$path';
// }

// class SearchProduct {
//   final int variantId;
//   final int materialId;
//   final String productName;
//   final String brandName;
//   final String categoryName;
//   final String subcategoryName;
//   final String sizeDimension;
//   final String thicknessOrSpec;
//   final String sku;
//   final int stock;
//   final double retailPrice;
//   final double gstPercent;
//   final String masterImage;

//   SearchProduct({
//     required this.variantId,
//     required this.materialId,
//     required this.productName,
//     required this.brandName,
//     required this.categoryName,
//     required this.subcategoryName,
//     required this.sizeDimension,
//     required this.thicknessOrSpec,
//     required this.sku,
//     required this.stock,
//     required this.retailPrice,
//     required this.gstPercent,
//     required this.masterImage,
//   });

//   factory SearchProduct.fromJson(Map<String, dynamic> json) {
//     double toDouble(dynamic v) {
//       if (v == null) return 0;
//       if (v is num) return v.toDouble();
//       return double.tryParse(v.toString()) ?? 0;
//     }

//     return SearchProduct(
//       variantId: json['variant_id'] as int? ?? 0,
//       materialId: json['material_id'] as int? ?? 0,
//       productName: json['product_name']?.toString() ?? '',
//       brandName: json['brand_name']?.toString() ?? '',
//       categoryName: json['category_name']?.toString() ?? '',
//       subcategoryName: json['subcategory_name']?.toString() ?? '',
//       sizeDimension: json['size_dimension']?.toString() ?? '',
//       thicknessOrSpec: json['thickness_or_spec']?.toString() ?? '',
//       sku: json['sku']?.toString() ?? '',
//       stock: json['stock'] as int? ?? 0,
//       retailPrice: toDouble(json['retail_price']),
//       gstPercent: toDouble(json['gst_percent']),
//       masterImage: _fullImageUrl(json['master_image']?.toString()),
//     );
//   }
// }
