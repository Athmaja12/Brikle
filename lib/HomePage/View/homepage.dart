import 'dart:async';

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/AppStyle/sharedproduct_card.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Category/View/category_page.dart';
import 'package:brikle/Category/View/categorydetail_screen.dart';
import 'package:brikle/HomePage/Controller/home_provider.dart';
import 'package:brikle/HomePage/Model/home_model.dart';
import 'package:brikle/HomePage/View/notificationpage.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:brikle/Wishlist/Controller/wishlist_provider.dart';
import 'package:brikle/Wishlist/View/wishlist_screen.dart';
import 'package:brikle/Wishlist/View/wishlistheart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Guards against malformed/empty URLs (e.g. "", "http://", stray
// whitespace) that pass a plain isNotEmpty/!= null check but aren't real
// network URLs — these crash image resolution with "No host specified
// in URI file:///" instead of falling through to errorBuilder. Same
// guard used in sharedproduct_card.dart, productdetails_page.dart, and
// the bestselling card.
bool _isValidImageUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;
  if (!(uri.isScheme('HTTP') || uri.isScheme('HTTPS'))) return false;
  if (uri.host.isEmpty) return false;
  return true;
}

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F6),
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header(controller: controller)),
                SliverToBoxAdapter(
                  child: _CarouselSection(controller: controller),
                ),
                SliverToBoxAdapter(
                  child: _CategoriesSection(
                    key: controller.categoriesSectionKey,
                    controller: controller,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _TopDealsSection(controller: controller),
                ),
                SliverToBoxAdapter(
                  child: _CategoryBanner(controller: controller),
                ),
                SliverToBoxAdapter(
                  child: _BestsellingSection(controller: controller),
                ),
                SliverToBoxAdapter(child: _PromoGrid(controller: controller)),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ── Header: Deliver To + logo + icons, search bar ──────────────────────────
class _Header extends StatelessWidget {
  final HomeController controller;
  const _Header({required this.controller});

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
                  onTap: () => _showPincodeSheet(context, controller),
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
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Get.to(() => const NotificationScreen());
                },
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: Colors.black87,
                ),
              ),
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

// ── Carousel — now auto-advances, image-URL-guarded ─────────────────────
class _CarouselSection extends StatefulWidget {
  final HomeController controller;
  const _CarouselSection({required this.controller});

  @override
  State<_CarouselSection> createState() => _CarouselSectionState();
}

class _CarouselSectionState extends State<_CarouselSection> {
  final PageController _pageController = PageController();
  int _page = 0;
  Timer? _autoPlayTimer;

  static const _autoPlayInterval = Duration(seconds: 4);
  static const _autoPlayAnimationDuration = Duration(milliseconds: 450);

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      final items = widget.controller.carousels;
      if (items.length <= 1 || !_pageController.hasClients) return;

      final nextPage = (_page + 1) % items.length;
      _pageController.animateToPage(
        nextPage,
        duration: _autoPlayAnimationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final items = widget.controller.carousels;
      if (items.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, 16),
          vertical: Responsive.space(context, 12),
        ),
        child: Column(
          children: [
            SizedBox(
              height: Responsive.height(context, 160),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _startAutoPlay();
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: items.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    // FIX: was Image.network(items[i].imageUrl, ...)
                    // unconditionally with only an errorBuilder — an
                    // empty/malformed string crashes before errorBuilder
                    // can catch it. Now gated behind _isValidImageUrl.
                    child: _isValidImageUrl(items[i].imageUrl)
                        ? Image.network(
                            items[i].imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) =>
                                Container(color: AppColors.dotInactive),
                          )
                        : Container(color: AppColors.dotInactive),
                  ),
                ),
              ),
            ),
            SizedBox(height: Responsive.space(context, 8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primaryGreen
                        : AppColors.dotInactive,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    });
  }
}

// ── Categories — image-URL-guarded ───────────────────────────────────────
class _CategoriesSection extends StatelessWidget {
  final HomeController controller;
  const _CategoriesSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.space(context, 16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Categories',
            style: AppTextStyles.welcomeBackTitle(
              context,
            ).copyWith(fontSize: 18),
          ),
          SizedBox(height: Responsive.space(context, 12)),
          SizedBox(
            height: (116.0 * MediaQuery.of(context).size.width / 390),
            child: Obx(
              () => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.categories.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: Responsive.space(context, 12)),
                itemBuilder: (context, index) {
                  final cat = controller.categories[index];
                  return Obx(() {
                    final selected =
                        controller.selectedCategoryIndex.value == index;

                    final scale = MediaQuery.of(context).size.width / 390;
                    const cardWidth = 105.0;
                    const cardHeight = 116.0;
                    const imageBoxHeight = 98.0;

                    return GestureDetector(
                      onTap: () {
                        controller.onCategoryTap(index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryProductsScreenWrapper(
                              categoryId: cat.id,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: cardWidth * scale,
                        height: cardHeight * scale,
                        decoration: BoxDecoration(
                          color: const Color(0xFF228B22),
                          borderRadius: BorderRadius.circular(8),
                          border: selected
                              ? Border.all(
                                  color: AppColors.primaryGreen,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: imageBoxHeight * scale,
                                padding: EdgeInsets.all(6 * scale),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F7E6),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  // FIX: old check was `cat.imageUrl != null`,
                                  // which is ALWAYS true — CategoryItem.imageUrl
                                  // is built via _fullImageUrl() in home_model.dart,
                                  // which always returns a String ('' when there's
                                  // nothing), never null. So this branch used to
                                  // always try Image.network, including on ''.
                                  // Now checks real validity instead.
                                  child: _isValidImageUrl(cat.imageUrl)
                                      ? Image.network(
                                          cat.imageUrl!,
                                          fit: BoxFit.contain,
                                          width: double.infinity,
                                        )
                                      : Container(color: AppColors.fieldFill),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              height: (cardHeight - imageBoxHeight) * scale,
                              child: Center(
                                child: Text(
                                  cat.name,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Product card — shared by Top Deals + Bestselling ────────────────────
class _ProductCard extends StatelessWidget {
  final DealItem product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDFF5E3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${product.discountPercent}% Off',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              WishlistHeart(variantId: product.variantId, size: 18),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _isValidImageUrl(product.imageUrl)
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 50,
                        color: Colors.black26,
                      ),
                    ),
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
                  )
                : const Center(
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 50,
                      color: Colors.black26,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.fieldLabel(
              context,
            ).copyWith(color: AppColors.textDark),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                '₹${product.dealPrice.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 6),
              Text(
                '₹${product.retailPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: AppColors.textGray,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${product.discountPercent}% off',
                style: const TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: wire to CartController.addToCart(product.variantId)
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                side: const BorderSide(color: AppColors.inputBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Add to Cart',
                style: TextStyle(color: AppColors.textDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top Deals of the Week ────────────────────────────────────────────────
class _TopDealsSection extends StatelessWidget {
  final HomeController controller;
  const _TopDealsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final activeDeals = controller.topDeals
          .where((d) => !d.isExpired)
          .toList();

      if (activeDeals.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: EdgeInsets.only(
          left: Responsive.space(context, 16),
          right: Responsive.space(context, 16),
          top: Responsive.space(context, 16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Top Deals of the Week',
                  style: AppTextStyles.welcomeBackTitle(
                    context,
                  ).copyWith(fontSize: 18),
                ),
                Text('View All', style: AppTextStyles.authPromptLink(context)),
              ],
            ),
            SizedBox(height: Responsive.space(context, 12)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeDeals.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 300,
              ),
              itemBuilder: (context, index) {
                final deal = activeDeals[index];
                return SharedProductCard(
                  product: CategoryProductItem(
                    variantId: deal.variantId,
                    materialId: deal.materialId,
                    name: deal.name,
                    imageUrl: deal.imageUrl,
                    price: deal.dealPrice,
                  ),
                  dealBadgeText: deal.customTitle,
                  dealEndDate: deal.endDate,
                  originalPrice: deal.retailPrice,
                  discountPercent: deal.discountPercent,
                );
              },
            ),
          ],
        ),
      );
    });
  }
}

// ── Category banner (image only, tap → Category page) ───────────────────
class _CategoryBanner extends StatelessWidget {
  final HomeController controller;
  const _CategoryBanner({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: Responsive.space(context, 16),
        right: Responsive.space(context, 16),
        bottom: Responsive.space(context, 12),
        top: 0,
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
            aspectRatio: 16 / 9,
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

// ── Bestselling on [Category] — tap-only, no cart (no variant data) ─────
class _BestsellingSection extends StatelessWidget {
  final HomeController controller;
  const _BestsellingSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isBestsellingLoading.value) {
        return const Padding(
          padding: EdgeInsets.all(10),
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.bestselling.isEmpty) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: EdgeInsets.only(
          left: Responsive.space(context, 16),
          right: Responsive.space(context, 16),
          top: Responsive.space(context, 12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bestselling on ${controller.selectedCategoryName}',
                  style: AppTextStyles.welcomeBackTitle(
                    context,
                  ).copyWith(fontSize: 18),
                ),
                Text('View All', style: AppTextStyles.authPromptLink(context)),
              ],
            ),
            SizedBox(height: Responsive.space(context, 12)),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.bestselling.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: 220,
              ),
              itemBuilder: (context, index) =>
                  _BestsellingCard(item: controller.bestselling[index]),
            ),
          ],
        ),
      );
    });
  }
}

class _BestsellingCard extends StatelessWidget {
  final BestSellingItem item;
  const _BestsellingCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              product: CategoryProductItem(
                variantId: 0,
                materialId: item.id,
                name: item.name,
                imageUrl: item.imageUrl,
                price: item.hasOffer ? item.dealPrice! : item.retailPrice,
                brandName: item.brandName,
              ),
            ),
          ),
        );
      },
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
            if (item.hasOffer)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDFF5E3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${item.discountPercent}% Off',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: _isValidImageUrl(item.imageUrl)
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 50,
                          color: Colors.black26,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 50,
                        color: Colors.black26,
                      ),
                    ),
            ),
            const SizedBox(height: 6),
            if (item.brandName != null && item.brandName!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  item.brandName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.fieldLabel(
                context,
              ).copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            if (item.hasOffer)
              Row(
                children: [
                  Text(
                    '₹${item.dealPrice!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '₹${item.retailPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: AppColors.textGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
            else
              Text(
                '₹${item.retailPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom 4-tile promo grid ──────────────────────────────────────────────
class _PromoGrid extends StatelessWidget {
  final HomeController controller;
  const _PromoGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 16),
        vertical: 0,
      ),
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
            onTap: () => controller.goToCategory(tile.categoryName),
            child: Semantics(
              button: true,
              label: tile.semanticLabel,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  tile.assetPath,
                  fit: BoxFit.contain,
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

void _showPincodeSheet(BuildContext context, HomeController controller) {
  final textController = TextEditingController(
    text: controller.deliverToPincode.value,
  );

  Timer? _debounceTimer;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.pincodeMessage.value = '';
        controller.isPincodeServiceable.value = true;
      });

      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Check delivery availability',
              style: AppTextStyles.welcomeBackTitle(
                context,
              ).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: (value) {
                controller.pincodeMessage.value = '';
                controller.isPincodeServiceable.value = true;
                _debounceTimer?.cancel();
                if (value.length == 6) {
                  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                    controller.checkPincode(value.trim());
                  });
                }
              },
              decoration: InputDecoration(
                hintText: 'Enter pincode',
                counterText: '',
                filled: true,
                fillColor: AppColors.fieldFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.inputBorder),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.isCheckingPincode.value) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (controller.pincodeMessage.value.isEmpty)
                return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      controller.isPincodeServiceable.value
                          ? Icons.check_circle
                          : Icons.error,
                      color: controller.isPincodeServiceable.value
                          ? AppColors.primaryGreen
                          : AppColors.errorRed,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        controller.pincodeMessage.value,
                        style: TextStyle(
                          color: controller.isPincodeServiceable.value
                              ? AppColors.primaryGreen
                              : AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final pin = textController.text.trim();
                  if (pin.length == 6) {
                    _debounceTimer?.cancel();
                    controller.checkPincode(pin);
                  } else {
                    Get.snackbar(
                      'Invalid Pincode',
                      'Please enter a valid 6-digit pincode',
                      snackPosition: SnackPosition.BOTTOM,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Check',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  ).whenComplete(() {
    _debounceTimer?.cancel();
  });
}
