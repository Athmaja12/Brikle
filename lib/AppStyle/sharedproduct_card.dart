import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/View/addtocart_view.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:brikle/Wishlist/Controller/wishlist_provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single shared product card — used on Home (Top Deals), Category listing,
/// and Product Detail's "Suggested for you". Reflects LIVE cart state via
/// CartController (not local widget state like the old per-screen cards
/// did): shows "Add to Cart" until this variant is in the cart, then shows
/// a quantity stepper.
///
/// Tapping the card body → Product Detail. Tapping "Add to Cart" (or
/// picking a bulk tier) → real API call, then navigates to Cart —
/// confirmed behavior, applies everywhere this card is used.
class SharedProductCard extends StatelessWidget {
  final CategoryProductItem product;
  const SharedProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final cartController = Get.find<CartController>();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      padding: const EdgeInsets.all(10),
      child: Obx(() {
        final cartItem = cartController.cartItems.firstWhereOrNull(
          (i) => i.variantId == product.variantId,
        );
        final quantity = cartItem?.quantity ?? 0;
        final unitPrice = product.unitPriceForQuantity(
          quantity == 0 ? 1 : quantity,
        );
        final totalPrice = unitPrice * (quantity == 0 ? 1 : quantity);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tappable info area → Product Detail. Buttons live OUTSIDE
            // this GestureDetector so tapping them doesn't also navigate.
            GestureDetector(
              behavior: HitTestBehavior.opaque,

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,

                    // child: Obx(
                    // () => GestureDetector(
                    //   onTap: () {
                    //     final wishlist = Get.find<WishlistController>();

                    //     wishlist.toggleWishlist(product);
                    //   },

                    //   child: Icon(
                    //     Get.find<WishlistController>().isWishlisted(
                    //           product.variantId,
                    //         )
                    //         ? Icons.favorite
                    //         : Icons.favorite_border,

                    //     size: 18,

                    //     color:
                    //         Get.find<WishlistController>().isWishlisted(
                    //           product.variantId,
                    //         )
                    //         ? Colors.red
                    //         : Colors.black,
                    //   ),
                    // ),
                    // ),
                  ),
                  SizedBox(
                    height: 78,
                    child: product.imageUrl.isNotEmpty
                        ? Image.network(
                            product.imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.inventory_2_outlined,
                              size: 60,
                              color: Colors.black26,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            size: 60,
                            color: Colors.black26,
                          ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 15 / 12,
                      color: const Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${unitPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  if (quantity > 1)
                    Text(
                      'Total: ₹${totalPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textGray,
                      ),
                    ),
                ],
              ),
            ),

            if (product.hasTiers && product.priceTiers.isNotEmpty)
              GestureDetector(
                onTap: () => _showBulkPricingDialog(context, cartController),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Unlock Bulk Prices of ₹${product.bestTierPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryGreen,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 6),

            // ── Add to Cart (qty 0) or live stepper (qty ≥ 1) ──────────
            quantity == 0
                ? GestureDetector(
                    onTap: () =>
                        _addToCartAndNavigate(context, cartController, 1),
                    child: Container(
                      width: double.infinity,
                      height: 35,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFB1B1B1)),
                      ),
                      child: Text(
                        'Add to Cart',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 31,
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _StepperSymbol(
                          label: '-',
                          onTap: () => cartController.decrement(cartItem!),
                        ),
                        Text(
                          '$quantity',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
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
                  ),
          ],
        );
      }),
    );
  }

  Future<void> _addToCartAndNavigate(
    BuildContext context,
    CartController cartController,
    int quantity,
  ) async {
    await cartController.addToCart(
      variantId: product.variantId,
      quantity: quantity,
    );
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => CartScreen()));
  }

  void _showBulkPricingDialog(
    BuildContext context,
    CartController cartController,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Bulk Prices Launched',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ...product.priceTiers.map(
                (t) => InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _addToCartAndNavigate(context, cartController, t.minQty);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: AppColors.textGray,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Buy ${t.minQty}+ at',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          '₹${t.price.toStringAsFixed(0)}/unit',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
