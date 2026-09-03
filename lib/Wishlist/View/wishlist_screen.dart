import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/BottomNavigation/bottomnavigation.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Category/View/category_page.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:brikle/Wishlist/Controller/wishlist_provider.dart';
import 'package:brikle/Wishlist/Model/wishlist_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Shared price formatter ──────────────────────────────────────────────
String _formatPrice(double amount) {
  final formatted = amount.toStringAsFixed(2);
  final parts = formatted.split('.');
  final integerPart = parts[0];
  final decimalPart = parts[1];
  final grouped = integerPart.replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (Match m) => '${m[1]},',
  );
  return '₹$grouped.$decimalPart';
}

class WishlistScreen extends GetView<WishlistController> {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(controller: controller),
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryGreen,
                    ),
                  );
                }
                if (controller.items.isEmpty) {
                  return const _EmptyWishlist();
                }
                return RefreshIndicator(
                  color: AppColors.primaryGreen,
                  onRefresh: controller.fetchWishlist,
                  child: ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: Responsive.space(context, 14),
                      vertical: Responsive.space(context, 8),
                    ),
                    itemCount: controller.items.length,
                    separatorBuilder: (_, __) => Divider(
                      height: Responsive.space(context, 1),
                      color: AppColors.inputBorder,
                    ),
                    itemBuilder: (context, index) => _WishlistItemRow(
                      item: controller.items[index],
                      controller: controller,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 0,
        onTap: (index) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => MainScreen(initialIndex: index)),
            (route) => false,
          );
        },
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final WishlistController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 4),
        vertical: Responsive.space(context, 2),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            color: AppColors.textDark,
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'My Wishlist',
              style: GoogleFonts.manrope(
                fontSize: Responsive.font(context, 18),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Obx(
            () => controller.items.isEmpty
                ? const SizedBox.shrink()
                : Padding(
                    padding: EdgeInsets.only(
                      right: Responsive.space(context, 12),
                    ),
                    child: Text(
                      '${controller.items.length} item${controller.items.length > 1 ? 's' : ''}',
                      style: GoogleFonts.manrope(
                        fontSize: Responsive.font(context, 12),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textGray,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Single wishlist row — compact, one row tall ─────────────────────────
// No card border, no full-width button, no shadow. Image + text + two
// small icon actions (favorite, add-to-cart) so each item takes minimal
// vertical space and more fit on screen without scrolling.
class _WishlistItemRow extends StatelessWidget {
  final WishlistItem item;
  final WishlistController controller;
  const _WishlistItemRow({required this.item, required this.controller});

  void _showRemoveSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.inputBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Remove from Wishlist?',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${item.materialName}, ${item.sizeDimension}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                color: AppColors.textGray,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.inputBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.manrope(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      controller.removeItem(item);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Remove',
                      style: GoogleFonts.manrope(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToProductDetail(BuildContext context) {
    // '/product-detail' is not a registered GetPage, so Get.toNamed()
    // throws inside GetX's PageRedirect. Navigate directly instead —
    // same pattern used by the cart screen's _CartItemRow._openProductDetail.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: CategoryProductItem(
            variantId: item.variantId,
            materialId: item.materialId,
            name: item.materialName,
            imageUrl: item.imageUrl,
            // Product Detail just displays whatever price it's handed —
            // it doesn't recompute GST itself. Pass the GST-inclusive
            // price so it matches what's shown on the Wishlist card
            // instead of falling back to the base retail price.
            price: item.priceWithGst,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToProductDetail(context),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: Responsive.space(context, 10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: Responsive.height(context, 56),
                height: Responsive.height(context, 56),
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: AppColors.fieldFill),
                      )
                    : Container(
                        color: AppColors.fieldFill,
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                          color: Colors.black26,
                        ),
                      ),
              ),
            ),
            SizedBox(width: Responsive.space(context, 10)),

            // ── Name, size, price ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.materialName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: Responsive.font(context, 13.5),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  SizedBox(height: Responsive.space(context, 2)),
                  Text(
                    item.sizeDimension,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: Responsive.font(context, 11.5),
                      fontWeight: FontWeight.w400,
                      color: AppColors.textGray,
                    ),
                  ),
                  SizedBox(height: Responsive.space(context, 3)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatPrice(item.priceWithGst),
                        style: GoogleFonts.manrope(
                          fontSize: Responsive.font(context, 14),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      SizedBox(width: Responsive.space(context, 4)),
                      Text(
                        'incl. GST',
                        style: GoogleFonts.manrope(
                          fontSize: Responsive.font(context, 10),
                          fontWeight: FontWeight.w400,
                          color: AppColors.textGray,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(width: Responsive.space(context, 6)),

            // ── Actions: heart (remove) + add-to-cart, both compact icons ──
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showRemoveSheet(context),
                  icon: const Icon(Icons.favorite_rounded),
                  color: Colors.red,
                  iconSize: Responsive.font(context, 19),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  splashRadius: 18,
                ),
                IconButton(
                  onPressed: () => controller.moveToCart(item),
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  color: AppColors.primaryGreen,
                  iconSize: Responsive.font(context, 19),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  splashRadius: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────
class _EmptyWishlist extends StatelessWidget {
  const _EmptyWishlist();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, 32),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              size: Responsive.font(context, 48),
              color: AppColors.textGray,
            ),
            SizedBox(height: Responsive.space(context, 14)),
            Text(
              'Your wishlist is empty',
              style: GoogleFonts.manrope(
                fontSize: Responsive.font(context, 16),
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            SizedBox(height: Responsive.space(context, 6)),
            Text(
              'Tap the heart on any product to save it here',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                color: AppColors.textGray,
                fontSize: Responsive.font(context, 12.5),
                fontWeight: FontWeight.w400,
              ),
            ),
            SizedBox(height: Responsive.space(context, 18)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(
                    vertical: Responsive.space(context, 12),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Continue Shopping',
                  style: GoogleFonts.manrope(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: Responsive.font(context, 13.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
