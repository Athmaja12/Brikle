import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/circularbackbutton.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/AppStyle/sharedproduct_card.dart';
import 'package:brikle/BottomNavigation/bottomnavigation.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Category/Controller/categorydeatail_controller.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
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
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _TopBar(),
              _Banner(categoryName: cat.name),
              _ProductCountHeader(controller: controller),
              _FilterRow(controller: controller),
              _ProductGrid(controller: controller),
              const SizedBox(height: 24),
            ],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Deliver To', style: AppTextStyles.termsText(context)),
                  Row(
                    children: [
                      Text(
                        '678001',
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
              const Spacer(),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'B',
                      style: AppTextStyles.brikleLogoAccent(
                        context,
                      ).copyWith(fontSize: 20),
                    ),
                    TextSpan(
                      text: 'rikle',
                      style: AppTextStyles.brikleLogoDark(
                        context,
                      ).copyWith(fontSize: 20),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.shopping_bag_outlined),
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

// ── Banner ────────────────────────────────────────────────────────────────
class _Banner extends StatelessWidget {
  final String categoryName;
  const _Banner({required this.categoryName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Responsive.space(context, 16)),
      child: Container(
        constraints: BoxConstraints(minHeight: Responsive.height(context, 150)),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.brown.shade900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Build Stronger,\nBuild Better',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Premium $categoryName for every Project',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 6),
            const Text(
              'Upto 50% off',
              style: TextStyle(
                color: Color(0xFFF5A623),
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5A623),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'SHOP NOW',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── "Cements  14 products" ───────────────────────────────────────────────
class _ProductCountHeader extends StatelessWidget {
  final CategoryProductsController controller;
  const _ProductCountHeader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final cat = controller.category.value;
      final count = controller.filteredProducts.length;
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
            Text('$count products', style: AppTextStyles.termsText(context)),
          ],
        ),
      );
    });
  }
}

// ── Filter row: Category / Brand / Type / Pack — instant-apply chips ────
class _FilterRow extends StatelessWidget {
  final CategoryProductsController controller;
  const _FilterRow({required this.controller});

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

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text('Filter:', style: AppTextStyles.termsText(context)),
              SizedBox(width: Responsive.space(context, 8)),
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
              ),
              SizedBox(width: Responsive.space(context, 8)),
              _FilterDropdownChip(
                label: controller.selectedType.value.isEmpty
                    ? 'Type'
                    : controller.selectedType.value,
                active: controller.selectedType.value.isNotEmpty,
                onTap: () => _showTypePicker(
                  context,
                  options.types,
                  controller.setTypeFilter,
                ),
              ),
              SizedBox(width: Responsive.space(context, 8)),
              _FilterDropdownChip(
                label: controller.selectedQuantity.value.isEmpty
                    ? 'Pack'
                    : controller.selectedQuantity.value,
                active: controller.selectedQuantity.value.isNotEmpty,
                onTap: () => _showTypePicker(
                  context,
                  options.quantities,
                  controller.setQuantityFilter,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showCategoryPicker(
    BuildContext context,
    CategoryFilterOptions options,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: options.categories
            .map(
              (c) => ListTile(
                title: Text(c.name),
                onTap: () {
                  Navigator.pop(context);
                  controller.switchCategory(context, c.id);
                },
              ),
            )
            .toList(),
      ),
    );
  }

  void _showBrandPicker(BuildContext context, CategoryFilterOptions options) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: const Text('All Brands'),
            onTap: () {
              controller.setBrandFilter(null);
              Navigator.pop(context);
            },
          ),
          ...options.brands.map(
            (b) => ListTile(
              title: Text(b.name),
              onTap: () {
                controller.setBrandFilter(b.id);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showTypePicker(
    BuildContext context,
    List<String> values,
    void Function(String) onPick,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        shrinkWrap: true,
        children: values
            .map(
              (v) => ListTile(
                title: Text(v),
                onTap: () {
                  onPick(v);
                  Navigator.pop(context);
                },
              ),
            )
            .toList(),
      ),
    );
  }
}

class _FilterDropdownChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterDropdownChip({
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: active ? Colors.white : AppColors.textDark,
              ),
            ),
            const SizedBox(width: 4),
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
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.52,
          ),
          itemBuilder: (context, index) =>
              SharedProductCard(product: products[index]),
        ),
      );
    });
  }
}

class _ProductCard extends StatefulWidget {
  final CategoryProductItem product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  int _quantity = 0; // 0 = "Add to Cart" button shown; ≥1 = stepper shown

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

          // Product name — Manrope 400 12px, #212121, matches Figma
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

          // Toggles between "Add to Cart" (qty 0) and green stepper (qty ≥ 1)
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
