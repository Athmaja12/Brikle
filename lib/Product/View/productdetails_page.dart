import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/View/addtocart_view.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/AppStyle/sharedproduct_card.dart';
import 'package:brikle/BottomNavigation/bottomnavigation.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/Controller/productdetails_controller.dart';
import 'package:brikle/Product/Model/productdetails_model.dart';
import 'package:brikle/Wishlist/View/wishlistheart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProductDetailScreen extends StatelessWidget {
  final CategoryProductItem product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      ProductDetailController(product: product),
      tag: 'product_detail_${product.variantId}',
    );

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
                      Text(
                        product.name,
                        style: AppTextStyles.welcomeBackTitle(
                          context,
                        ).copyWith(fontSize: 18),
                      ),
                      SizedBox(height: Responsive.space(context, 8)),
                      Text(
                        '₹${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('per unit', style: AppTextStyles.termsText(context)),

                      if (product.hasTiers &&
                          product.priceTiers.isNotEmpty) ...[
                        SizedBox(height: Responsive.space(context, 10)),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9F1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.primaryGreen.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_offer_outlined,
                                    size: 16,
                                    color: AppColors.primaryGreen,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Bulk Pricing',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.primaryGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...product.priceTiers.map(
                                (tier) => InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () {
                                    controller.applyBulkTier(tier.minQty);
                                    Get.snackbar(
                                      'Bulk Price Applied',
                                      'Qty set to ${tier.minQty} at ₹${tier.price.toStringAsFixed(0)}/unit',
                                      backgroundColor: AppColors.primaryGreen,
                                      colorText: Colors.white,
                                      snackPosition: SnackPosition.BOTTOM,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        SizedBox(height: Responsive.space(context, 4)),
                        Text(
                          'Incl. GST. Shipping calculated at checkout.',
                          style: AppTextStyles.termsText(context),
                        ),
                      ],
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
                    style: AppTextStyles.loginSubtitle(
                      context,
                    ).copyWith(fontSize: 14, color: AppColors.textGray),
                  ),
                ),
                _ExpandableSection(
                  title: 'Product Description',
                  expanded: controller.descriptionExpanded,
                  onTap: controller.toggleDescription,
                  child: Text(
                    controller.detail.value?.description ?? '',
                    style: AppTextStyles.loginSubtitle(
                      context,
                    ).copyWith(fontSize: 14, color: AppColors.textGray),
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
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  f.question,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  f.answer,
                                  style: const TextStyle(
                                    color: AppColors.textGray,
                                    fontSize: 13,
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
                    style: TextStyle(fontSize: 14, color: AppColors.textGray),
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
                                childAspectRatio: 0.75,
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

// ── Image gallery: main image + thumbnail strip, back + wishlist overlay ──
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
                child: WishlistHeart(
                  variantId: controller.product.variantId,
                  withBackground: true,
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

// ── Suggestion card: image + name + brand only, no price/cart ──────────
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
          ],
        ),
      ),
    );
  }
}

// ── Collapsible section — chevron flips, content shows/hides ────────────
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
              child: Align(alignment: Alignment.centerLeft, child: child),
            ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
