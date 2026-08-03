// Replacement for `_ProductVariantCard` in paint_calculator_screen.dart
//
// WHAT CHANGED AND WHY
// ─────────────────────
// 1. Bug: "suggested products can't see the increment button"
//    The old card only ever rendered a static "Add to Cart" / "Out of
//    Stock" button (or a spinner while adding). There was no branch that
//    checked whether the variant was already in the cart, so a +/-
//    stepper could never appear — the UI had no state for it.
//
//    Fix: wrap the button area in an Obx that reads CartController
//    (the same GetX controller SharedProductCard already uses) and
//    looks up this variant's quantity via `firstWhereOrNull`. If
//    quantity == 0 -> show "Add to Cart"; if quantity > 0 -> show a
//    stepper row (-, qty, +), matching the pattern in SharedProductCard.
//
// 2. Bug: "click Add to Cart goes directly to cart page"
//    The old _handleAddToCart() unconditionally called
//    Navigator.pushAndRemoveUntil(...MainScreen(initialIndex: 3)...)
//    after every successful add — wiping the nav stack and jumping to
//    the Cart tab every single time, regardless of what the user
//    wanted to do next (e.g. add another variant, or bump quantity).
//
//    Fix: removed the forced navigation entirely. Adding to cart now
//    just updates local state (via CartController, which is already
//    reactive) and shows a snackbar — the user stays on the Calculate
//    page and can keep adjusting quantity or browsing other variants.

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/Calculation/Controller/productCalculation_provider.dart';
import 'package:brikle/Calculation/Model/productCalculator_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductVariantCard extends StatelessWidget {
  final PaintVariant variant;
  final String productName;
  final PaintCalculatorProvider provider;

  static const double cardWidth = 170;

  const ProductVariantCard({
    super.key,
    required this.variant,
    required this.productName,
    required this.provider,
  });

  bool get _inStock => variant.stockStatus.toLowerCase().contains('in stock');

  // Adds the item to cart. No navigation here anymore — the card's own
  // Obx (driven by CartController.cartItems) will flip from the button
  // to the stepper automatically once the cart updates.
  Future<void> _handleAddToCart(BuildContext context) async {
    final cartController = Get.find<CartController>();
    await cartController.addToCart(
      variantId: variant.variantId,
      quantity: 1,
    );
    // addToCart() already calls fetchCart() internally and shows its own
    // "Added to Cart" snackbar (see addtocart_provider.dart), so nothing
    // else is needed here — the Obx below reacts to cartItems changing.
  }

  Widget _buildThumbnail() {
    final imageUrl = provider.productImageUrl;

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
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: Image.network(
                  imageUrl,
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
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.format_paint,
                    size: 32,
                    color: Colors.grey,
                  ),
                ),
              )
            : provider.isLoadingImage
            ? const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : const Center(
                child: Icon(Icons.format_paint, size: 32, color: Colors.grey),
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
          _buildThumbnail(),
          const SizedBox(height: 8),
          Text(
            productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            variant.packSize,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                variant.price,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  variant.stockStatus,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _inStock
                        ? const Color(0xFF2E7D32)
                        : Colors.orange[800],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Add to Cart button OR +/- stepper, driven by cart state ──
          Obx(() {
            final cartItem = cartController.cartItems.firstWhereOrNull(
              (i) => i.variantId == variant.variantId,
            );
            final quantity = cartItem?.quantity ?? 0;

            if (quantity == 0) {
              return SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton(
                  onPressed: !_inStock
                      ? null
                      : () => _handleAddToCart(context),
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
                    _inStock ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            // In cart — show stepper instead of the button.
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