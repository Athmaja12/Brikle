import 'dart:async';

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/AppStyle/sharedproduct_card.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Category/View/category_page.dart';
import 'package:brikle/Category/View/categorydetail_screen.dart';
import 'package:brikle/HomePage/Controller/home_provider.dart';
import 'package:brikle/HomePage/Controller/search_Provider.dart';
import 'package:brikle/HomePage/Model/home_model.dart';
import 'package:brikle/HomePage/View/search_bar.dart';
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
    // Registration only — HomeController.onInit() already triggers its
    // own refresh() the moment it's created (ideally pre-warmed in
    // LoginView before navigation), so nothing extra is scheduled here.
    if (!Get.isRegistered<HomeController>()) {
      Get.put(HomeController());
    }
    if (!Get.isRegistered<GlobalSearchController>()) {
      Get.put(GlobalSearchController());
    }

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
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
          // Logo centering: a plain Row with Spacer()/Spacer() only
          // centers the logo within whatever space is *left over* after
          // the "Deliver To" block and the icon cluster — since those
          // two are different widths, the logo drifted off-center.
          // Stacking a full-width Row (left content + icons, pinned to
          // the edges) underneath a separately centered logo guarantees
          // the logo sits at the true midpoint of the header.
          Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppColors.primaryGreen,
                    size: 18,
                  ),
                  SizedBox(width: Responsive.space(context, 4)),
                  Obx(() {
                    final pincode = controller.deliverToPincode.value.trim();
                    final hasPincode =
                        pincode.isNotEmpty &&
                        RegExp(r'^\d+$').hasMatch(pincode);

                    return GestureDetector(
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasPincode)
                                Text(
                                  pincode,
                                  style: AppTextStyles.fieldLabel(context)
                                      .copyWith(
                                        color: AppColors.textDark,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              const Icon(Icons.keyboard_arrow_down, size: 16),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
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
                ],
              ),
              // Sits on top, centered on the Stack itself — not affected
              // by how wide the Row's children are.
              IgnorePointer(
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Br',
                        style: AppTextStyles.brikleLogoAccent(
                          context,
                        ).copyWith(fontSize: 25),
                      ),
                      TextSpan(
                        text: 'ikle',
                        style: AppTextStyles.brikleLogoDark(
                          context,
                        ).copyWith(fontSize: 25),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Responsive.space(context, 12)),
          const GlobalSearchBar(),
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
  late final PageController _pageController;
  int _page =
      0; // raw (unbounded) page index — actual item is _page % items.length
  Timer? _autoPlayTimer;
  DateTime? _lastTapTime;

  static const _autoPlayInterval = Duration(seconds: 4);
  static const _autoPlayAnimationDuration = Duration(milliseconds: 450);

  // Large multiplier so the user can swipe back and forth for the entire
  // session without ever hitting page 0 or the max page — that's what
  // makes it feel infinite in both directions, not just forward auto-play.
  static const int _virtualMultiplier = 5000;

  @override
  void initState() {
    super.initState();
    final items = widget.controller.carousels;
    final itemCount = items.isEmpty ? 1 : items.length;
    // Start deep in the virtual range, aligned so (_page % itemCount) == 0,
    // i.e. we visually start on the real first slide.
    _page = _virtualMultiplier * itemCount ~/ 2;
    _pageController = PageController(initialPage: _page);
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_autoPlayInterval, (_) {
      final items = widget.controller.carousels;
      if (items.length <= 1 || !_pageController.hasClients || !mounted) return;

      // Always move forward by exactly 1 — never wraps, so animateToPage
      // never has to animate backward through the whole list.
      _pageController.nextPage(
        duration: _autoPlayAnimationDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _onBannerTap(CarouselItem item) {
    final materialId = item.material;
    final categoryId = item.category;

    // Step 3: If both material and category are null, do nothing (standalone banner)
    if (materialId == null && categoryId == null) {
      return;
    }

    // Debounce rapid taps
    final now = DateTime.now();
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!) < const Duration(milliseconds: 500)) {
      return;
    }
    _lastTapTime = now;

    // Step 1: Material navigation priority
    if (materialId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            product: CategoryProductItem(
              variantId: 0,
              materialId: materialId,
              name: item.materialName ?? item.title,
              imageUrl: item.imageUrl,
              price: 0,
            ),
          ),
        ),
      );
    }
    // Step 2: Category navigation priority
    else if (categoryId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryProductsScreenWrapper(categoryId: categoryId),
        ),
      );
    }
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
        // Top spacing removed — the Header already ends with its own
        // bottom padding, so this section used to add a second gap
        // right underneath it.
        padding: EdgeInsets.only(
          left: Responsive.space(context, 16),
          right: Responsive.space(context, 16),
          top: Responsive.space(context, 8),
          bottom: Responsive.space(context, 8),
        ),
        child: Column(
          children: [
            SizedBox(
              height: Responsive.height(context, 160),
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollStartNotification &&
                      notification.dragDetails != null) {
                    _startAutoPlay(); // restart timer on manual swipe, same as before
                  }
                  return false;
                },
                child: PageView.builder(
                  controller: _pageController,
                  // Effectively unlimited — user/auto-play can move forward
                  // (or backward, via manual swipe) for the whole session
                  // without ever reaching this bound.
                  itemCount: _virtualMultiplier * items.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final actualIndex = i % items.length;
                    final item = items[actualIndex];
                    return GestureDetector(
                      onTap: () => _onBannerTap(item),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              Container(color: AppColors.dotInactive),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(height: Responsive.space(context, 8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(items.length, (i) {
                final active = (_page % items.length) == i;
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
          SizedBox(height: Responsive.space(context, 8)),
          SizedBox(
            height: (132.0 * MediaQuery.of(context).size.width / 390),
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
                    const cardWidth = 120.0;
                    const cardHeight = 132.0;
                    const imageBoxHeight = 110.0;

                    return GestureDetector(
                      onTap: () async {
                        controller.onCategoryTap(index);
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryProductsScreenWrapper(
                              categoryId: cat.id,
                            ),
                          ),
                        );
                        // Back on Home — clear the highlight so it doesn't
                        // stay stuck on whatever category was last opened.
                        controller.resetAfterCategoryVisit();
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
                                padding: EdgeInsets.all(7 * scale),
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
                                    fontSize: 12,
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
          bottom: Responsive.space(context, 10),
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
                // Text('View All', style: AppTextStyles.authPromptLink(context)),
              ],
            ),
            SizedBox(height: Responsive.space(context, 10)),
            _buildDealsRows(activeDeals),
          ],
        ),
      );
    });
  }

  // Builds 2-per-row pairs of deal cards. Each row is wrapped in
  // IntrinsicHeight so both cards in the pair match height and size to
  // their own content — no hardcoded mainAxisExtent to keep in sync with
  // SharedProductCard's internals (that's what caused the earlier
  // overflow/dead-space back-and-forth with GridView's fixed row height).
  Widget _buildDealsRows(List<DealItem> deals) {
    final rows = <Widget>[];
    for (int i = 0; i < deals.length; i += 2) {
      final first = deals[i];
      final second = i + 1 < deals.length ? deals[i + 1] : null;

      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _dealCard(first)),
              const SizedBox(width: 5),
              Expanded(
                child: second != null
                    ? _dealCard(second)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _dealCard(DealItem deal) {
    return SharedProductCard(
      product: CategoryProductItem(
        variantId: deal.variantId,
        materialId: deal.materialId,
        name: deal.name,
        imageUrl: deal.imageUrl,
        price: deal.dealPrice,
        isAssured: deal.isAssured, // NEW
        assuredCertificate: deal.assuredCertificate,
      ),
      // dealBadgeText: deal.customTitle,
      // dealEndDate: deal.endDate,
      originalPrice: deal.retailPrice,
      discountPercent: deal.discountPercent,
    );
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
        bottom: Responsive.space(context, 16),
        top: Responsive.space(context, 16),
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
          top: Responsive.space(context, 10),
          bottom: Responsive.space(context, 16),
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
                // Text('View All', style: AppTextStyles.authPromptLink(context)),
              ],
            ),
            SizedBox(height: Responsive.space(context, 8)),
            _buildBestsellingRows(controller.bestselling),
          ],
        ),
      );
    });
  }

  Widget _buildBestsellingRows(List<BestSellingItem> items) {
    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final first = items[i];
      final second = i + 1 < items.length ? items[i + 1] : null;

      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));

      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: _bestsellingCard(first)),
              const SizedBox(width: 5),
              Expanded(
                child: second != null
                    ? _bestsellingCard(second)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _bestsellingCard(BestSellingItem item) {
    return SharedProductCard(
      product: CategoryProductItem(
        variantId: item.id,
        materialId: item.id,
        name: item.name,
        imageUrl: item.imageUrl,
        price: item.hasOffer ? item.dealPrice! : item.retailPrice,
        brandName: item.brandName,
        isAssured: item.isAssured, // NEW
        assuredCertificate: item.assuredCertificate,
      ),
      originalPrice: item.hasOffer ? item.retailPrice : null,
      discountPercent: item.hasOffer ? item.discountPercent : null,
    );
  }
}

// class _BestsellingCard extends StatelessWidget {
//   final BestSellingItem item;
//   const _BestsellingCard({required this.item});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: () {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => ProductDetailScreen(
//               product: CategoryProductItem(
//                 variantId: 0,
//                 materialId: item.id,
//                 name: item.name,
//                 imageUrl: item.imageUrl,
//                 price: item.hasOffer ? item.dealPrice! : item.retailPrice,
//                 brandName: item.brandName,
//               ),
//             ),
//           ),
//         );
//       },
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: AppColors.inputBorder),
//         ),
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (item.hasOffer)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 4),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 6,
//                     vertical: 2,
//                   ),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFDFF5E3),
//                     borderRadius: BorderRadius.circular(6),
//                   ),
//                   child: Text(
//                     '${item.discountPercent}% Off',
//                     style: const TextStyle(
//                       fontSize: 11,
//                       color: AppColors.primaryGreen,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ),
//             Expanded(
//               child: _isValidImageUrl(item.imageUrl)
//                   ? Image.network(
//                       item.imageUrl,
//                       fit: BoxFit.contain,
//                       width: double.infinity,
//                       errorBuilder: (_, __, ___) => const Center(
//                         child: Icon(
//                           Icons.inventory_2_outlined,
//                           size: 50,
//                           color: Colors.black26,
//                         ),
//                       ),
//                     )
//                   : const Center(
//                       child: Icon(
//                         Icons.inventory_2_outlined,
//                         size: 50,
//                         color: Colors.black26,
//                       ),
//                     ),
//             ),
//             const SizedBox(height: 6),
//             if (item.brandName != null && item.brandName!.isNotEmpty)
//               Padding(
//                 padding: const EdgeInsets.only(bottom: 2),
//                 child: Text(
//                   item.brandName!,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: const TextStyle(
//                     fontSize: 10,
//                     color: AppColors.textGray,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             Text(
//               item.name,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//               style: AppTextStyles.fieldLabel(
//                 context,
//               ).copyWith(color: AppColors.textDark),
//             ),
//             const SizedBox(height: 4),
//             if (item.hasOffer)
//               Row(
//                 children: [
//                   Text(
//                     '₹${item.dealPrice!.toStringAsFixed(0)}',
//                     style: const TextStyle(
//                       fontWeight: FontWeight.w700,
//                       fontSize: 14,
//                     ),
//                   ),
//                   const SizedBox(width: 6),
//                   Text(
//                     '₹${item.retailPrice.toStringAsFixed(0)}',
//                     style: const TextStyle(
//                       decoration: TextDecoration.lineThrough,
//                       color: AppColors.textGray,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ],
//               )
//             else
//               Text(
//                 '₹${item.retailPrice.toStringAsFixed(0)}',
//                 style: const TextStyle(
//                   fontWeight: FontWeight.w700,
//                   fontSize: 14,
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// ── Bottom 4-tile promo grid ──────────────────────────────────────────────
class _PromoGrid extends StatelessWidget {
  final HomeController controller;
  const _PromoGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 16),
        vertical: 10,
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

// ── SIMPLIFIED PINCODE CHECKING UI ──────────────────────────────────────────
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
    backgroundColor: Colors.white,
    builder: (sheetContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.pincodeMessage.value = '';
        controller.isPincodeServiceable.value = true;
      });

      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Enter Pincode',
              style: AppTextStyles.welcomeBackTitle(
                context,
              ).copyWith(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Check delivery availability in your area',
              style: AppTextStyles.termsText(
                context,
              ).copyWith(fontSize: 13, color: AppColors.textGray),
            ),
            const SizedBox(height: 20),

            // Pincode input
            TextField(
              controller: textController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              autofocus: true,
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
                hintText: 'Enter 6-digit pincode',
                counterText: '',
                prefixIcon: Icon(
                  Icons.location_on_outlined,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                filled: true,
                fillColor: AppColors.fieldFill,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.primaryGreen,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Status message
            Obx(() {
              if (controller.pincodeMessage.value.isEmpty)
                return const SizedBox.shrink();

              final isServiceable = controller.isPincodeServiceable.value;
              final color = isServiceable
                  ? AppColors.primaryGreen
                  : AppColors.errorRed;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      isServiceable
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: color,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        controller.pincodeMessage.value,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Obx(() {
                    final isValid = textController.text.trim().length == 6;
                    final isChecking = controller.isCheckingPincode.value;
                    final hasMessage =
                        controller.pincodeMessage.value.isNotEmpty;
                    final isServiceable = controller.isPincodeServiceable.value;

                    return ElevatedButton(
                      onPressed: isValid && !isChecking
                          ? () {
                              final pin = textController.text.trim();
                              controller.checkPincode(pin);
                              if (isServiceable) {
                                Future.delayed(
                                  const Duration(milliseconds: 600),
                                  () {
                                    if (controller.isPincodeServiceable.value) {
                                      Navigator.pop(sheetContext);
                                    }
                                  },
                                );
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isValid
                            ? AppColors.primaryGreen
                            : Colors.grey.shade300,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        minimumSize: const Size(0, 48),
                      ),
                      child: isChecking
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              hasMessage && isServiceable ? 'Apply' : 'Check',
                              style: TextStyle(
                                color: isValid
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      );
    },
  ).whenComplete(() {
    _debounceTimer?.cancel();
  });
}
