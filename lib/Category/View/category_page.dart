import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/pincode.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/Category/Controller/category_controller.dart';
import 'package:brikle/Category/Model/category_model.dart';
import 'package:brikle/Wishlist/Controller/wishlist_provider.dart';
import 'package:brikle/Wishlist/View/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategoryPage extends GetView<CategoryController> {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<CategoryController>()) {
      Get.put(CategoryController());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F6),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              children: [
                _SearchHeader(controller: controller),
                _CategoriesGridSection(controller: controller),
                _OfferZoneBanner(controller: controller),
                _PromoGridSection(controller: controller),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────
// Replace the old _SearchHeader class entirely with this:
class _SearchHeader extends StatelessWidget {
  final CategoryController controller;
  const _SearchHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 16),
        vertical: Responsive.space(context, 12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primaryGreen, size: 18),
              SizedBox(width: Responsive.space(context, 4)),
              Obx(
                () => GestureDetector(
                  onTap: () => showPincodeSheet(
                    context: context,
                    deliverToPincode: controller.deliverToPincode,
                    isCheckingPincode: controller.isCheckingPincode,
                    isPincodeServiceable: controller.isPincodeServiceable,
                    pincodeMessage: controller.pincodeMessage,
                    onCheck: controller.checkPincode,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Deliver To',
                        style: AppTextStyles.termsText(context),
                      ),
                      Row(
                        children: [
                          Text(
                            controller.deliverToPincode.value,
                            style: AppTextStyles.fieldLabel(context).copyWith(
                              color: AppColors.textDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Br',
                      style: AppTextStyles.brikleLogoAccent(
                        context,
                      ).copyWith(fontSize: 20),
                    ),
                    TextSpan(
                      text: 'ikle',
                      style: AppTextStyles.brikleLogoDark(
                        context,
                      ).copyWith(fontSize: 20),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => Get.to(() => const WishlistScreen()),
                child: Obx(() {
                  final count = Get.find<WishlistController>().items.length;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.favorite_border_rounded,
                        size: 22,
                        color: Colors.black87,
                      ),
                      if (count > 0)
                        Positioned(
                          top: -4,
                          right: -6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            constraints: const BoxConstraints(
                              minWidth: 10,
                              minHeight: 10,
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
              SizedBox(width: Responsive.space(context, 16)),
              const Icon(Icons.notifications_none_rounded),
            ],
          ),
          SizedBox(height: Responsive.space(context, 12)),
          Container(
            height: Responsive.height(context, 44),
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.space(context, 12),
            ),
            decoration: BoxDecoration(
              color: AppColors.fieldFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textGray, size: 20),
                SizedBox(width: Responsive.space(context, 8)),
                Expanded(
                  child: Text(
                    "Search for 'Asian Paints'",
                    style: AppTextStyles.loginSubtitle(
                      context,
                    ).copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── All Categories — 2-column grid, tap navigates to Category Detail ─────
class _CategoriesGridSection extends StatelessWidget {
  final CategoryController controller;

  const _CategoriesGridSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.of(context).size.width / 390;

    const cardHeight = 119.0;
    const imageHeight = 98.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 16),
        vertical: Responsive.space(context, 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "All Categories",
            style: AppTextStyles.welcomeBackTitle(
              context,
            ).copyWith(fontSize: 18),
          ),

          SizedBox(height: Responsive.space(context, 16)),

          Obx(
            () => GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 170 / 119,
              ),
              itemBuilder: (context, index) {
                final category = controller.categories[index];

                return GestureDetector(
                  onTap: () => controller.openCategory(context, category),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF228B22),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        /// Image Area
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: imageHeight * scale,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F7E6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.all(8 * scale),
                            child:
                                category.imageUrl != null &&
                                    category.imageUrl!.isNotEmpty
                                ? Image.network(
                                    category.imageUrl!,
                                    fit: BoxFit.contain,
                                  )
                                : const Icon(
                                    Icons.category_outlined,
                                    color: Colors.grey,
                                    size: 40,
                                  ),
                          ),
                        ),

                        /// Name
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: (cardHeight - imageHeight) * scale,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Offer Zone — single static banner ────────────────────────────────────
class _OfferZoneBanner extends StatelessWidget {
  final CategoryController controller;
  const _OfferZoneBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Responsive.space(context, 16),
        right: Responsive.space(context, 16),
        bottom: Responsive.space(context, 12),
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryPage()),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9, // matches the Figma banner card proportions
            child: Image.asset(
              'assets/images/banner.png',
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bottom 4-tile promo grid — asset-based, tap navigates by category name ─
class _PromoGridSection extends StatelessWidget {
  final CategoryController controller;
  const _PromoGridSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.space(context, 16)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.promoTiles.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.7,
        ),
        itemBuilder: (context, index) {
          final tile = controller.promoTiles[index];
          return GestureDetector(
            onTap: () =>
                controller.openCategoryByName(context, tile.categoryName),
            child: Semantics(
              button: true,
              label: tile.semanticLabel,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  tile.assetPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
