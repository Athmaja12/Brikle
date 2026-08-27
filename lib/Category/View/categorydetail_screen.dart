import 'dart:async';

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/circularbackbutton.dart';
import 'package:brikle/AppStyle/pincode.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/AppStyle/sharedproduct_card.dart';
import 'package:brikle/BottomNavigation/bottomnavigation.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Category/Controller/categorydeatail_controller.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Category/View/category_page.dart';
import 'package:brikle/HomePage/Controller/home_provider.dart';
import 'package:brikle/HomePage/Controller/search_Provider.dart';
import 'package:brikle/HomePage/View/search_bar.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:brikle/Wishlist/Controller/wishlist_provider.dart';
import 'package:brikle/Wishlist/View/wishlist_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wrapper handles per-category-id controller instantiation so switching
/// categories (via filter dropdown) creates a fresh controller instance
/// instead of reusing stale data from a previous category.
class CategoryProductsScreenWrapper extends StatelessWidget {
  final int categoryId;
  const CategoryProductsScreenWrapper({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(
      CategoryProductsController(categoryId: categoryId),
      tag: 'category_products_$categoryId',
    );
    return CategoryProductsScreen(controller: controller);
  }
}

class CategoryProductsScreen extends StatelessWidget {
  final CategoryProductsController controller;
  const CategoryProductsScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<GlobalSearchController>()) {
      Get.put(GlobalSearchController());
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F6),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final cat = controller.category.value;
          if (cat == null) {
            return const Center(child: Text('Could not load category'));
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _TopBar(controller: controller),
                _Banner(categoryName: cat.name),
                _ProductCountHeader(controller: controller),
                _FilterRow(controller: controller),
                _ProductGrid(controller: controller),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 1, // Category tab
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

// ── Top bar: Deliver To + logo + icons + search (matches Home/Category tab) ─
class _TopBar extends StatelessWidget {
  final CategoryProductsController controller;
  const _TopBar({required this.controller});

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
                    final homeController = Get.find<HomeController>();
                    final pincode = homeController.deliverToPincode.value
                        .trim();
                    final hasPincode =
                        pincode.isNotEmpty &&
                        RegExp(r'^\d+$').hasMatch(pincode);

                    return GestureDetector(
                      onTap: () => _showPincodeSheet(context, homeController),
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
              IgnorePointer(
                child: RichText(
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

// ── Banner ────────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  final String categoryName;
  const _Banner({required this.categoryName});

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

// ── "Cements  14 products" ───────────────────────────────────────────────
class _ProductCountHeader extends StatelessWidget {
  final CategoryProductsController controller;
  const _ProductCountHeader({required this.controller});

  String _getSortLabel() {
    switch (controller.selectedSort.value) {
      case 'price_low_to_high':
        return ' (Price: Low → High)';
      case 'price_high_to_low':
        return ' (Price: High → Low)';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cat = controller.category.value;
      final count = controller.filteredProducts.length;
      final sortLabel = _getSortLabel();
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              cat?.name ?? '',
              style: AppTextStyles.welcomeBackTitle(
                context,
              ).copyWith(fontSize: 20),
            ),
            Text(
              '$count products$sortLabel',
              style: AppTextStyles.termsText(context),
            ),
          ],
        ),
      );
    });
  }
}

// ── Filter row: Category / Brand / Type / Pack / Sort ────────────────────
class _FilterRow extends StatelessWidget {
  final CategoryProductsController controller;
  const _FilterRow({required this.controller});

  bool _anyFilterActive() {
    return controller.selectedBrandId.value != null ||
        controller.selectedType.value.isNotEmpty ||
        controller.selectedQuantity.value.isNotEmpty ||
        controller.selectedSort.value != 'default';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 16),
        vertical: Responsive.space(context, 10),
      ),
      child: Obx(() {
        final options = controller.filterOptions.value;
        if (options == null) return const SizedBox.shrink();

        final anyActive = _anyFilterActive();

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: AppColors.textGray),
              SizedBox(width: Responsive.space(context, 6)),
              _FilterDropdownChip(
                label: 'Category',
                onTap: () => _showCategoryPicker(context, options),
              ),
              SizedBox(width: Responsive.space(context, 8)),
              _FilterDropdownChip(
                label: controller.selectedBrandId.value == null
                    ? 'Brand'
                    : options.brands
                          .firstWhere(
                            (b) => b.id == controller.selectedBrandId.value,
                          )
                          .name,
                active: controller.selectedBrandId.value != null,
                onTap: () => _showBrandPicker(context, options),
                onClear: controller.selectedBrandId.value != null
                    ? () => controller.setBrandFilter(null)
                    : null,
              ),
              SizedBox(width: Responsive.space(context, 8)),
              _FilterDropdownChip(
                label: controller.selectedType.value.isEmpty
                    ? 'Type'
                    : controller.selectedType.value,
                active: controller.selectedType.value.isNotEmpty,
                onTap: () => _showOptionPicker(
                  context,
                  title: 'Type',
                  values: options.types,
                  selected: controller.selectedType.value,
                  onPick: controller.setTypeFilter,
                ),
                onClear: controller.selectedType.value.isNotEmpty
                    ? () => controller.setTypeFilter('')
                    : null,
              ),
              SizedBox(width: Responsive.space(context, 8)),
              _FilterDropdownChip(
                label: controller.selectedQuantity.value.isEmpty
                    ? 'Pack'
                    : controller.selectedQuantity.value,
                active: controller.selectedQuantity.value.isNotEmpty,
                onTap: () => _showOptionPicker(
                  context,
                  title: 'Pack Size',
                  values: options.quantities,
                  selected: controller.selectedQuantity.value,
                  onPick: controller.setQuantityFilter,
                ),
                onClear: controller.selectedQuantity.value.isNotEmpty
                    ? () => controller.setQuantityFilter('')
                    : null,
              ),
              // NEW: Sort Chip
              SizedBox(width: Responsive.space(context, 8)),
              _SortDropdownChip(
                selectedSort: controller.selectedSort.value,
                onTap: () => _showSortPicker(context),
              ),
              if (anyActive) ...[
                SizedBox(width: Responsive.space(context, 8)),
                GestureDetector(
                  onTap: () {
                    controller.clearFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.errorRed.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: AppColors.errorRed,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Clear all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.errorRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  // ── Option Picker ──────────────────────────────────────────────────────
  void _showOptionPicker(
    BuildContext context, {
    required String title,
    required List<String> values,
    required String selected,
    required void Function(String) onPick,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _FilterPickerSheet(
        title: title,
        items: [
          _PickerItem(label: 'All $title', isSelected: selected.isEmpty),
          ...values.map(
            (v) => _PickerItem(label: v, isSelected: v == selected),
          ),
        ],
        onSelect: (index) {
          Navigator.pop(sheetCtx);
          onPick(index == 0 ? '' : values[index - 1]);
        },
      ),
    );
  }

  // ── Category Picker ────────────────────────────────────────────────────
  void _showCategoryPicker(
    BuildContext context,
    CategoryFilterOptions options,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _FilterPickerSheet(
        title: 'Category',
        items: options.categories
            .map((c) => _PickerItem(label: c.name, isSelected: false))
            .toList(),
        onSelect: (index) {
          Navigator.pop(sheetCtx);
          controller.switchCategory(context, options.categories[index].id);
        },
      ),
    );
  }

  // ── Brand Picker ──────────────────────────────────────────────────────
  void _showBrandPicker(BuildContext context, CategoryFilterOptions options) {
    final selectedId = controller.selectedBrandId.value;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _FilterPickerSheet(
        title: 'Brand',
        items: [
          _PickerItem(label: 'All Brands', isSelected: selectedId == null),
          ...options.brands.map(
            (b) => _PickerItem(label: b.name, isSelected: b.id == selectedId),
          ),
        ],
        onSelect: (index) {
          Navigator.pop(sheetCtx);
          controller.setBrandFilter(
            index == 0 ? null : options.brands[index - 1].id,
          );
        },
      ),
    );
  }

  // ── Sort Picker ───────────────────────────────────────────────────────
  void _showSortPicker(BuildContext context) {
    final currentSort = controller.selectedSort.value;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _FilterPickerSheet(
        title: 'Sort by Price',
        items: [
          _PickerItem(label: 'Default', isSelected: currentSort == 'default'),
          _PickerItem(
            label: 'Price: Low to High',
            isSelected: currentSort == 'price_low_to_high',
          ),
          _PickerItem(
            label: 'Price: High to Low',
            isSelected: currentSort == 'price_high_to_low',
          ),
        ],
        onSelect: (index) {
          Navigator.pop(sheetCtx);
          final sortOptions = [
            'default',
            'price_low_to_high',
            'price_high_to_low',
          ];
          controller.setSort(sortOptions[index]);
        },
      ),
    );
  }
}

// ── Sort Dropdown Chip ──────────────────────────────────────────────────
class _SortDropdownChip extends StatelessWidget {
  final String selectedSort;
  final VoidCallback onTap;

  const _SortDropdownChip({required this.selectedSort, required this.onTap});

  String _getDisplayLabel() {
    switch (selectedSort) {
      case 'price_low_to_high':
        return 'Price: Low ↑';
      case 'price_high_to_low':
        return 'Price: High ↓';
      default:
        return 'Sort';
    }
  }

  bool get isActive => selectedSort != 'default';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 12,
          right: isActive ? 6 : 12,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? AppColors.primaryGreen : AppColors.inputBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.swap_vert_rounded,
              size: 16,
              color: isActive ? Colors.white : AppColors.textGray,
            ),
            const SizedBox(width: 4),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                _getDisplayLabel(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (isActive)
              GestureDetector(
                onTap: () {
                  final controller = Get.find<CategoryProductsController>();
                  controller.setSort('default');
                },
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isActive ? Colors.white : AppColors.textDark,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Dropdown Chip ─────────────────────────────────────────────────
class _FilterDropdownChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _FilterDropdownChip({
    required this.label,
    this.active = false,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(
          left: 12,
          right: active && onClear != null ? 6 : 12,
          top: 8,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primaryGreen : AppColors.inputBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 4),
            if (active && onClear != null)
              GestureDetector(
                onTap: onClear,
                child: const Padding(
                  padding: EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              )
            else
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: active ? Colors.white : AppColors.textDark,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Data for one row inside a picker sheet ───────────────────────────────
class _PickerItem {
  final String label;
  final bool isSelected;
  const _PickerItem({required this.label, required this.isSelected});
}

// ── Consistent bottom-sheet UI shared by every filter picker ────────────
class _FilterPickerSheet extends StatelessWidget {
  final String title;
  final List<_PickerItem> items;
  final void Function(int index) onSelect;

  const _FilterPickerSheet({
    required this.title,
    required this.items,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                    color: AppColors.textGray,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return InkWell(
                    onTap: () => onSelect(index),
                    child: Container(
                      width: double.infinity,
                      color: item.isSelected
                          ? AppColors.primaryGreen.withOpacity(0.07)
                          : Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: item.isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: item.isSelected
                                    ? AppColors.primaryGreen
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                          Icon(
                            item.isSelected
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 20,
                            color: item.isSelected
                                ? AppColors.primaryGreen
                                : AppColors.inputBorder,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }
}

// ── Product grid ──────────────────────────────────────────────────────────
class _ProductGrid extends StatelessWidget {
  final CategoryProductsController controller;
  const _ProductGrid({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final products = controller.filteredProducts;

      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.space(context, 16),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            final crossAxisCount = width >= 900
                ? 4
                : width >= 600
                ? 3
                : 2;

            const spacing = 12.0;
            final cardWidth =
                (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

            final textScale = MediaQuery.of(context).textScaler.scale(1);
            final cardHeight = cardWidth * 1.8 * textScale;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: spacing,
                crossAxisSpacing: spacing,
                mainAxisExtent: cardHeight,
              ),
              // itemBuilder: (context, index) {
              //   final product = products[index];
              //   return SharedProductCard(
              //     key: ValueKey('product_${product.variantId}'),
              //     product: product,
              //   );
              // },
              itemBuilder: (context, index) {
                final product = products[index];
                final offer = product.offer;
                final discountedPrice = offer != null
                    ? product.price * (1 - offer.discountPercentage / 100)
                    : product.price;

                return SharedProductCard(
                  key: ValueKey('product_${product.variantId}'),
                  product: product.copyWith(
                    price: discountedPrice,
                  ), // see note below
                  originalPrice: offer != null ? product.price : null,
                  discountPercent: offer?.discountPercentage.toInt(),
                );
              },
            );
          },
        ),
      );
    });
  }
}

// ── Product Card ─────────────────────────────────────────────────────────
class _ProductCard extends StatefulWidget {
  final CategoryProductItem product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _quantity = 0;

  double get _unitPrice =>
      widget.product.unitPriceForQuantity(_quantity == 0 ? 1 : _quantity);
  double get _totalPrice => _unitPrice * (_quantity == 0 ? 1 : _quantity);

  void _addToCart() => setState(() => _quantity = 1);
  void _increment() => setState(() => _quantity++);
  void _decrement() {
    setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 0);
  }

  void _showBulkPricingDialog() {
    final tiers = widget.product.priceTiers;
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
                widget.product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ...tiers.map(
                (t) => InkWell(
                  onTap: () {
                    setState(() => _quantity = t.minQty);
                    Navigator.pop(ctx);
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
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
          const Align(
            alignment: Alignment.topRight,
            child: Icon(Icons.favorite_border, size: 18),
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
            '₹${_unitPrice.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          if (_quantity > 1)
            Text(
              'Total: ₹${_totalPrice.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textGray),
            ),
          if (product.hasTiers && product.priceTiers.isNotEmpty)
            GestureDetector(
              onTap: _showBulkPricingDialog,
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
          _quantity == 0
              ? GestureDetector(
                  onTap: _addToCart,
                  child: Container(
                    width: double.infinity,
                    height: 35,
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 11,
                    ),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFB1B1B1),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Add to Cart',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.55,
                        color: const Color(0xFF000000),
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
                      _StepperSymbol(label: '-', onTap: _decrement),
                      Text(
                        '$_quantity',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 20 / 12,
                          color: Colors.white,
                        ),
                      ),
                      _StepperSymbol(label: '+', onTap: _increment),
                    ],
                  ),
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 20 / 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryGreen),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.primaryGreen),
      ),
    );
  }
}

// ── Pincode Sheet ─────────────────────────────────────────────────────────
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
