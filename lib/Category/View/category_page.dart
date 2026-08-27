import 'dart:async';

import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/Category/Controller/category_controller.dart';
import 'package:brikle/HomePage/Controller/home_provider.dart';
import 'package:brikle/HomePage/Controller/search_Provider.dart';
import 'package:brikle/HomePage/View/search_bar.dart';
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
                  // Notification icon removed per request.
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
