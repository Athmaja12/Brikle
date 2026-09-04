// lib/Calculation/product_Card.dart
//
// Single reusable product card used by every calculator's "related /
// suggested products" row (paint, block, and any future calculator).
//
// Design notes:
// - Takes plain fields (title, subtitle, priceText, imageUrl, variantId,
//   inStock) instead of a calculator-specific model, so it has no
//   knowledge of PaintVariant or RelatedBlockProduct. Each screen maps
//   its own model to these fields at the call site.
// - Image loading state is passed in per-card (isImageLoading) rather
//   than read from a single provider field, because some calculators
//   (block) show multiple products with independent image loads, while
//   others (paint) show variants of one product sharing one image.
// - Cart interaction (Add to Cart / stepper) is self-contained here via
//   CartController, identical logic for every calculator.

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SharedProductCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String priceText;
  final String? imageUrl;
  final bool isImageLoading;
  final IconData placeholderIcon;
  final int variantId;
  final int materialId; // ← NEW, required
  final double price;
  final bool inStock;
  final String? stockLabel;

  static const double cardWidth = 170;

  const SharedProductCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.priceText,
    required this.imageUrl,
    required this.isImageLoading,
    required this.variantId,
    required this.materialId, // ← NEW
    required this.price,
    this.placeholderIcon = Icons.shopping_bag_outlined,
    this.inStock = true,
    this.stockLabel,
  });
  void _openProductDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: CategoryProductItem(
            variantId: variantId,
            materialId: materialId,
            name: title,
            imageUrl: imageUrl ?? '',
            price: price,
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    final cartController = Get.find<CartController>();
    await cartController.addToCart(variantId: variantId, quantity: 1);
    // addToCart() calls fetchCart() and shows its own snackbar
    // (see addtocart_provider.dart) — the Obx below reacts automatically.
  }

  Widget _buildThumbnail() {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        clipBehavior: Clip.antiAlias,
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint(
                      '[SharedProductCard] ⚠️ Image.network failed: $imageUrl',
                    );
                    return Icon(placeholderIcon, size: 32, color: Colors.grey);
                  },
                ),
              )
            : isImageLoading
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : Center(
                child: Icon(placeholderIcon, size: 32, color: Colors.grey),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Scrollable, flexible content area — prevents overflow ──
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openProductDetail(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildThumbnail(),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        priceText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (stockLabel != null) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            stockLabel!,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: inStock
                                  ? const Color(0xFF2E7D32)
                                  : Colors.orange[800],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── Add to Cart button OR +/- stepper — UNCHANGED ──────────
          Obx(() {
            final cartItem = cartController.cartItems.firstWhereOrNull(
              (i) => i.variantId == variantId,
            );
            final quantity = cartItem?.quantity ?? 0;

            if (quantity == 0) {
              return SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton(
                  onPressed: !inStock ? null : () => _handleAddToCart(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    inStock ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            return Container(
              width: double.infinity,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StepperSymbol(
                    label: '-',
                    onTap: () {
                      if (quantity <= 1) {
                        cartController.removeItem(cartItem!);
                      } else {
                        cartController.decrement(cartItem!);
                      }
                    },
                  ),
                  Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  _StepperSymbol(
                    label: '+',
                    onTap: () => cartController.increment(cartItem!),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StepperSymbol extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _StepperSymbol({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
