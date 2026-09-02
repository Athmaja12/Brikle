import 'dart:math' as math;

import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/BottomNavigation/bottomnavigation.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/Controller/productdetails_controller.dart';
import 'package:brikle/Product/Model/productdetails_model.dart';
import 'package:brikle/Wishlist/View/wishlistheart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

class ProductDetailScreen extends StatelessWidget {
  final CategoryProductItem? product;
  final double? originalPrice;
  final int? discountPercent;
  final int? variantId;

  const ProductDetailScreen({
    super.key,
    this.product,
    this.originalPrice,
    this.discountPercent,
    this.variantId,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we have a product or variantId
    final args = Get.arguments as Map<String, dynamic>?;
    final variantIdFromArgs = args?['variantId'] as int?;
    final effectiveVariantId = variantId ?? variantIdFromArgs;

    // If we don't have a product but have variantId, fetch product details
    if (product == null && effectiveVariantId != null) {
      // You can fetch product details here using the variantId
      // For now, we'll show a loading state
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading product details...',
                style: AppTextStyles.termsText(context),
              ),
            ],
          ),
        ),
      );
    }

    // If we have a product, use it
    if (product != null) {
      // FIX: variantId is 0 for every "Suggested for you" placeholder
      // (it's only resolved after the material loads), so tagging by
      // variantId alone collapsed every suggestion onto the same
      // "product_detail_0" GetX instance — Get.put() doesn't overwrite
      // an existing tag, so the first suggestion opened would silently
      // "win" and get shown for every subsequent suggestion tapped.
      //
      // materialId is always unique and always correct (it's what the
      // API call actually fetches by), so combine both into the tag.
      final controllerTag =
          'product_detail_${product!.materialId}_${product!.variantId}';

      // Also force a fresh controller instance for this tag every time
      // the screen opens, rather than trusting whatever GetX already
      // has registered — protects against stale data if the same
      // product is revisited with different placeholder data (e.g. a
      // suggestion resolves to a real variantId after its first visit).
      if (Get.isRegistered<ProductDetailController>(tag: controllerTag)) {
        Get.delete<ProductDetailController>(tag: controllerTag, force: true);
      }

      final controller = Get.put(
        ProductDetailController(
          product: product!,
          originalPrice: originalPrice,
          discountPercent: discountPercent,
        ),
        tag: controllerTag,
      );

      return _buildProductDetail(context, controller);
    }
    // Fallback: show empty state
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'Product not found',
              style: AppTextStyles.welcomeBackTitle(context),
            ),
            const SizedBox(height: 8),
            Text(
              'The product you\'re looking for doesn\'t exist',
              style: AppTextStyles.termsText(context),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.back(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go Back',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetail(
    BuildContext context,
    ProductDetailController controller,
  ) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _ImageGallery(controller: controller),
                Padding(
                  padding: EdgeInsets.all(Responsive.space(context, 16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (controller.detail.value?.brandName != null)
                        Text(
                          controller.detail.value!.brandName!,
                          style: AppTextStyles.termsText(context),
                        ),
                      SizedBox(height: Responsive.space(context, 4)),
                      Obx(
                        () => Text(
                          controller.activeProduct.value.name,
                          style: AppTextStyles.welcomeBackTitle(
                            context,
                          ).copyWith(fontSize: 18),
                        ),
                      ),

                      SizedBox(height: Responsive.space(context, 8)),

                      // ── Price + MRP strike-through + discount badge ──
                      Obx(() {
                        final hasOffer = controller.hasOffer;
                        final displayPrice = hasOffer
                            ? controller.discountedPrice
                            : controller.activeProduct.value.price;
                        final originalPriceValue = hasOffer
                            ? controller.originalPriceValue
                            : null;
                        final discountPercentValue = hasOffer
                            ? controller.discountPercentageValue
                            : 0;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '₹${displayPrice.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: hasOffer
                                        ? AppColors.primaryGreen
                                        : AppColors.textDark,
                                  ),
                                ),
                                if (hasOffer && originalPriceValue != null) ...[
                                  SizedBox(width: Responsive.space(context, 8)),
                                  Text(
                                    '₹${originalPriceValue.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      decoration: TextDecoration.lineThrough,
                                      color: AppColors.textGray,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                                if (hasOffer && discountPercentValue > 0) ...[
                                  SizedBox(width: Responsive.space(context, 8)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDFF5E3),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '$discountPercentValue% Off',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'per unit',
                              style: AppTextStyles.termsText(context),
                            ),

                            // Show "Limited Time Deal" if offer exists
                            if (hasOffer) ...[
                              SizedBox(height: Responsive.space(context, 4)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: Colors.amber.shade300,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.local_offer_outlined,
                                      size: 14,
                                      color: Colors.amber.shade700,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Limited Time Deal',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      }),

                      Obx(() {
                        final active = controller.activeProduct.value;
                        if (!active.hasTiers || active.priceTiers.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                            top: Responsive.space(context, 10),
                          ),
                          child: _BulkPricingCard(
                            product: active,
                            controller: controller,
                          ),
                        );
                      }),

                      SizedBox(height: Responsive.space(context, 4)),
                      Text(
                        'Incl. GST. Shipping calculated at checkout.',
                        style: AppTextStyles.termsText(context),
                      ),

                      // ── Offers preview ──────────────────────────
                      Obx(() {
                        if (controller.isLoadingOffers.value) {
                          return const SizedBox.shrink();
                        }
                        if (controller.offers.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: EdgeInsets.only(
                            top: Responsive.space(context, 10),
                          ),
                          child: _OffersCard(offers: controller.offers),
                        );
                      }),

                      SizedBox(height: Responsive.space(context, 16)),

                      Obx(() {
                        final qty = controller.cartQuantity.value;
                        return qty == 0
                            ? SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: controller.addToCart,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Add to Cart',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            : Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    GestureDetector(
                                      onTap: controller.decrementQuantity,
                                      behavior: HitTestBehavior.opaque,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          '−',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '$qty',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: controller.incrementQuantity,
                                      behavior: HitTestBehavior.opaque,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                        ),
                                        child: Text(
                                          '+',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                      }),
                    ],
                  ),
                ),
                const Divider(height: 1),
                _ExpandableSection(
                  title: 'Product Highlights',
                  expanded: controller.highlightsExpanded,
                  onTap: controller.toggleHighlights,
                  child: Text(
                    controller.detail.value?.productHighlights.isNotEmpty ==
                            true
                        ? controller.detail.value!.productHighlights
                        : 'No highlights available.',
                    textAlign: TextAlign.left,
                    style: AppTextStyles.loginSubtitle(context).copyWith(
                      fontSize: 14,
                      color: AppColors.textGray,
                      height: 1.5,
                    ),
                  ),
                ),
                _ExpandableSection(
                  title: 'Product Description',
                  expanded: controller.descriptionExpanded,
                  onTap: controller.toggleDescription,
                  child: Text(
                    controller.detail.value?.description ?? '',
                    textAlign: TextAlign.left,
                    style: AppTextStyles.loginSubtitle(context).copyWith(
                      fontSize: 14,
                      color: AppColors.textGray,
                      height: 1.5,
                    ),
                  ),
                ),
                _ExpandableSection(
                  title: "FAQ's",
                  expanded: controller.faqsExpanded,
                  onTap: controller.toggleFaqs,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: (controller.detail.value?.faqs ?? [])
                        .map(
                          (f) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.question,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  f.answer,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    color: AppColors.textGray,
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                _ExpandableSection(
                  title: 'Returns & Exchange Policy',
                  expanded: controller.returnsExpanded,
                  onTap: controller.toggleReturns,
                  child: const Text(
                    '7-day easy returns available on this product. Item must be unused '
                    'and in original packaging. Refunds processed within 5-7 business days.',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textGray,
                      height: 1.5,
                    ),
                  ),
                ),

                Obx(() {
                  if (controller.suggestedProducts.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: Responsive.space(context, 20)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(context, 16),
                        ),
                        child: Text(
                          'Suggested for you',
                          style: AppTextStyles.welcomeBackTitle(
                            context,
                          ).copyWith(fontSize: 16),
                        ),
                      ),
                      SizedBox(height: Responsive.space(context, 12)),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: Responsive.space(context, 16),
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: controller.suggestedProducts.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.65,
                              ),
                          itemBuilder: (context, index) =>
                              _SuggestedProductCard(
                                suggestion: controller.suggestedProducts[index],
                                onTap: () => controller.openSuggestion(
                                  context,
                                  controller.suggestedProducts[index],
                                ),
                              ),
                        ),
                      ),
                      SizedBox(height: Responsive.space(context, 24)),
                    ],
                  );
                }),
              ],
            ),
          ),
        );
      }),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1,
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

// ── Bulk Pricing card ─────────────────────────────────────────────────────
class _BulkPricingCard extends StatefulWidget {
  final CategoryProductItem product;
  final ProductDetailController controller;

  const _BulkPricingCard({required this.product, required this.controller});

  @override
  State<_BulkPricingCard> createState() => _BulkPricingCardState();
}

class _BulkPricingCardState extends State<_BulkPricingCard> {
  OverlayEntry? _burstOverlay;

  @override
  void dispose() {
    _burstOverlay?.remove();
    _burstOverlay = null;
    super.dispose();
  }

  void _showBurst(BuildContext rowContext, double price) {
    _burstOverlay?.remove();
    _burstOverlay = null;

    final renderObject = rowContext.findRenderObject();

    if (renderObject is! RenderBox) {
      return;
    }

    if (!renderObject.hasSize) {
      return;
    }

    final position = renderObject.localToGlobal(Offset.zero);

    final rowWidth = renderObject.size.width;
    final rowHeight = renderObject.size.height;

    final centerX = position.dx + (rowWidth / 2);

    final centerY = position.dy + (rowHeight / 2);

    const boxSize = 200.0;
    const popupWidth = 190.0;

    final overlayState = Overlay.of(context);

    late final OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) {
        return Positioned(
          left: centerX - (boxSize / 2),
          top: centerY - (boxSize / 2),
          width: boxSize,
          height: boxSize,
          child: IgnorePointer(
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                const _CelebrationBurst(),

                SizedBox(
                  width: popupWidth,
                  child: _UnlockPill(price: price),
                ),
              ],
            ),
          ),
        );
      },
    );

    _burstOverlay = entry;

    overlayState.insert(entry);

    Future.delayed(const Duration(milliseconds: 1700), () {
      if (_burstOverlay == entry) {
        entry.remove();
        _burstOverlay = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.local_offer_outlined,
                size: 16,
                color: AppColors.primaryGreen,
              ),
              SizedBox(width: 6),
              Text(
                'Bulk Pricing',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.primaryGreen,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ...widget.product.priceTiers.asMap().entries.map((entry) {
            final index = entry.key;
            final tier = entry.value;

            return Builder(
              builder: (rowContext) {
                return InkWell(
                  borderRadius: BorderRadius.circular(8),

                  onTap: () async {
                    await widget.controller.applyBulkTier(tier.minQty);

                    if (!mounted) {
                      return;
                    }

                    _showBurst(rowContext, tier.price);

                    Get.snackbar(
                      'Bulk Price Applied',
                      'Qty set to ${tier.minQty} '
                          'at ₹${tier.price.toStringAsFixed(0)}/unit',
                      backgroundColor: AppColors.primaryGreen,
                      colorText: Colors.white,
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  },

                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Buy ${tier.minQty}+ units',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),

                        Text(
                          '₹${tier.price.toStringAsFixed(0)}/unit',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryGreen,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Apply',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

// ── Offers preview ────────────────────────────────────────────────────────
class _OffersCard extends StatelessWidget {
  final List<CouponModel> offers;
  const _OffersCard({required this.offers});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFC107).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(
                Icons.confirmation_number_outlined,
                size: 16,
                color: Color(0xFFB28704),
              ),
              SizedBox(width: 6),
              Text(
                'Available Offers',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFFB28704),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...offers
              .take(2)
              .map(
                (coupon) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 5,
                        color: AppColors.textGray,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: coupon.couponCode,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: AppColors.textDark,
                                ),
                              ),
                              TextSpan(
                                text:
                                    ' — ${coupon.discountPercentage.toStringAsFixed(0)}% off on ${coupon.rewardMaterialName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (offers.length > 2)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${offers.length - 2} more offer${offers.length - 2 > 1 ? 's' : ''} — apply at checkout',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textGray,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Image gallery ─────────────────────────────────────────────────────────
class _ImageGallery extends StatelessWidget {
  final ProductDetailController controller;
  const _ImageGallery({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final images = controller.galleryImages;
      final selected = controller.selectedImageIndex.value.clamp(
        0,
        images.length - 1,
      );

      return Column(
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: images[selected].isNotEmpty
                    ? Image.network(
                        images[selected],
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.inventory_2_outlined,
                          size: 100,
                          color: Colors.black26,
                        ),
                      )
                    : const Icon(
                        Icons.inventory_2_outlined,
                        size: 100,
                        color: Colors.black26,
                      ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.share_outlined,
                      onTap: () => _shareProduct(controller),
                    ),
                    const SizedBox(width: 8),
                    WishlistHeart(
                      variantId: controller.product.variantId,
                      withBackground: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (images.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => controller.selectImage(i),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: i == selected
                              ? AppColors.primaryGreen
                              : AppColors.inputBorder,
                          width: i == selected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: images[i].isNotEmpty
                            ? Image.network(
                                images[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: AppColors.fieldFill),
                              )
                            : Container(color: AppColors.fieldFill),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

void _shareProduct(ProductDetailController controller) {
  final name = controller.detail.value?.name.isNotEmpty == true
      ? controller.detail.value!.name
      : controller.activeProduct.value.name;
  final price = controller.activeProduct.value.price;
  Share.share('Check out $name for ₹${price.toStringAsFixed(0)} on Brikle!');
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}

// ── Suggested Product Card ──────────────────────────────────────────────
class _SuggestedProductCard extends StatelessWidget {
  final SmartSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestedProductCard({required this.suggestion, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inputBorder),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: suggestion.imageUrl.isNotEmpty
                      ? Image.network(
                          suggestion.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.inventory_2_outlined,
                            size: 50,
                            color: Colors.black26,
                          ),
                        )
                      : const Icon(
                          Icons.inventory_2_outlined,
                          size: 50,
                          color: Colors.black26,
                        ),
                ),
                if (suggestion.isBestSelling)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7A00),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'BESTSELLER',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (suggestion.brandName.isNotEmpty)
              Text(
                suggestion.brandName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.termsText(context),
              ),
            const SizedBox(height: 2),
            Text(
              suggestion.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              children: const [
                Text(
                  'View details',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 2),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 12,
                  color: AppColors.primaryGreen,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Expandable Section ──────────────────────────────────────────────────
class _ExpandableSection extends StatelessWidget {
  final String title;
  final RxBool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _ExpandableSection({
    required this.title,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  Icon(
                    expanded.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ],
              ),
            ),
          ),
          if (expanded.value)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(width: double.infinity, child: child),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

// ── Unlock Pill ──────────────────────────────────────────────────────────
class _UnlockPill extends StatelessWidget {
  final double price;
  const _UnlockPill({required this.price});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [const _ConfettiBurst(), _buildPill()],
        ),
      ),
    );
  }

  Widget _buildPill() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.scale(scale: 0.7 + (0.3 * value), child: child),
      ),
      child: Container(
        constraints: const BoxConstraints(minWidth: 0),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFD9F7E3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primaryGreen, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '🎉 You unlocked ₹${price.toStringAsFixed(0)}!',
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF15803D),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Confetti Burst ──────────────────────────────────────────────────────
class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst();

  static const _colors = [
    Color(0xFFFFC107),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
  ];

  @override
  Widget build(BuildContext context) {
    const particleCount = 10;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: List.generate(particleCount, (i) {
        final angle = (2 * math.pi / particleCount) * i;
        final color = _colors[i % _colors.length];
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOut,
          builder: (context, t, child) {
            final distance = 30 * t;
            final dx = distance * math.cos(angle);
            final dy = distance * math.sin(angle);
            return Opacity(
              opacity: (1 - t).clamp(0, 1),
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.scale(scale: 1 - (t * 0.4), child: child),
              ),
            );
          },
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      }),
    );
  }
}

// ── Celebration Burst ───────────────────────────────────────────────────
class _CelebrationBurst extends StatelessWidget {
  const _CelebrationBurst();

  static const _colors = [
    Color(0xFFFFC107),
    Color(0xFFEF5350),
    Color(0xFF42A5F5),
    Color(0xFF66BB6A),
    Color(0xFFAB47BC),
    Color(0xFFFF7043),
    Color(0xFF26C6DA),
    Color(0xFFEC407A),
  ];

  @override
  Widget build(BuildContext context) {
    const particleCount = 24;
    final rnd = math.Random();

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: List.generate(particleCount, (i) {
        final angle =
            (2 * math.pi / particleCount) * i + (rnd.nextDouble() * 0.4 - 0.2);
        final distance = 60.0 + rnd.nextDouble() * 40;
        final size = 5.0 + rnd.nextDouble() * 5;
        final color = _colors[i % _colors.length];
        final isSquare = i.isEven;
        final spinTurns = 0.5 + rnd.nextDouble() * 1.5;
        final delayMs = rnd.nextInt(80);

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 750 + delayMs),
          curve: Curves.easeOut,
          builder: (context, t, child) {
            final dx = distance * t * math.cos(angle);
            final dy = distance * t * math.sin(angle) + (18 * t * t);
            return Opacity(
              opacity: (1 - t).clamp(0, 1),
              child: Transform.translate(
                offset: Offset(dx, dy),
                child: Transform.rotate(
                  angle: spinTurns * 2 * math.pi * t,
                  child: Transform.scale(scale: 1 - (t * 0.3), child: child),
                ),
              ),
            );
          },
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: isSquare ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: isSquare ? BorderRadius.circular(1.5) : null,
            ),
          ),
        );
      }),
    );
  }
}
