// lib/AddtoCart/View/addtocart_view.dart

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/View/addresschange_modal.dart';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/AddtoCart/View/ordersuccess_screen.dart'
    show OrderSuccessScreen;
import 'package:brikle/ApiConfiguration/auth_gate.dart';
import 'package:brikle/ApiConfiguration/apiservice.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:brikle/Category/Model/categorydetail_model.dart';
import 'package:brikle/Product/View/productdetails_page.dart';
import 'package:brikle/Registration/View/regitration_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  // Used by the Cart ListView for smooth scrolling.
  static final ScrollController scrollController = ScrollController();
  // Payment section location.
  static final GlobalKey paymentMethodKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F6),
      body: SafeArea(
        child: Obx(() {
          if (controller.isCheckingOut.value) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          return const _CartBody();
        }),
      ),
    );
  }

  /// Smoothly scrolls the Cart page to the Payment Method section.
  static Future<void> scrollToPaymentMethod() async {
    debugPrint('[CartScreen] scrollToPaymentMethod() called');

    for (int attempt = 0; attempt < 15; attempt++) {
      await Future.delayed(const Duration(milliseconds: 100));

      await WidgetsBinding.instance.endOfFrame;

      final BuildContext? targetContext = paymentMethodKey.currentContext;

      final ScrollController scroll = CartScreen.scrollController;

      debugPrint(
        '[CartScreen] attempt=${attempt + 1} '
        'context=${targetContext != null} '
        'hasClients=${scroll.hasClients}',
      );

      if (targetContext == null) {
        continue;
      }

      if (!scroll.hasClients) {
        continue;
      }

      // Make sure the target belongs to the scrollable.
      final RenderObject? renderObject = targetContext.findRenderObject();

      if (renderObject == null) {
        continue;
      }

      debugPrint(
        '[CartScreen] Payment widget found. '
        'Starting ensureVisible...',
      );

      await Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,

        // Put Payment Method near the top of
        // the available screen.
        alignment: 0.08,

        alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
      );

      debugPrint('[CartScreen] AUTO SCROLL COMPLETED');

      return;
    }

    debugPrint(
      '[CartScreen] AUTO SCROLL FAILED '
      'after 15 attempts',
    );
  }
}

class _CartBody extends StatefulWidget {
  const _CartBody();

  @override
  State<_CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<_CartBody> {
  final CartController controller = Get.find<CartController>();

  Worker? _addressWorker;

  @override
  void initState() {
    super.initState();

    // Listen specifically for address changes.
    _addressWorker = ever(controller.selectedAddress, (address) {
      if (address != null) {
        debugPrint(
          '[CartScreen] selectedAddress changed → '
          'schedule payment scroll',
        );

        _schedulePaymentScroll();
      }
    });
  }

  void _schedulePaymentScroll() {
    // First frame after Obx rebuild.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;

      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) return;

      await CartScreen.scrollToPaymentMethod();
    });
  }

  @override
  void dispose() {
    _addressWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _TopBar(controller: controller),

        Expanded(
          child: RefreshIndicator(
            color: AppColors.primaryGreen,

            onRefresh: () => controller.fetchCart(showLoader: false),

            child: Obx(
              () => controller.cartItems.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [_EmptyCart()],
                    )
                  : ListView(
                      controller: CartScreen.scrollController,

                      physics: const AlwaysScrollableScrollPhysics(),

                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(context, 16),
                      ),

                      children: [
                        SizedBox(height: Responsive.space(context, 12)),

                        // =============================================
                        // PAYMENT SECTION - ONLY SHOWN WHEN ADDRESS EXISTS
                        // =============================================
                        Obx(() {
                          final hasAddress =
                              controller.selectedAddress.value != null;

                          if (!hasAddress) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            children: [
                              _PaymentMethodSelector(
                                key: CartScreen.paymentMethodKey,
                                controller: controller,
                              ),

                              SizedBox(height: Responsive.space(context, 16)),
                            ],
                          );
                        }),

                        // =============================================
                        // CART ITEMS
                        // =============================================
                        _CartItemsCard(controller: controller),

                        SizedBox(height: Responsive.space(context, 12)),

                        _CouponCard(controller: controller),

                        SizedBox(height: Responsive.space(context, 12)),

                        _GstinCard(controller: controller),

                        SizedBox(height: Responsive.space(context, 12)),

                        _BillDetailsCard(controller: controller),

                        SizedBox(height: Responsive.space(context, 12)),

                        _CancellationPolicyCard(controller: controller),

                        SizedBox(height: Responsive.space(context, 16)),

                        // =============================================
                        // ADD ADDRESS / PAYMENT PROMPT / CHECKOUT BUTTON
                        // - MOVED TO THE BOTTOM
                        // =============================================
                        Obx(() {
                          final hasAddress =
                              controller.selectedAddress.value != null;

                          final hasPayment =
                              controller.hasSelectedPaymentMethod.value;

                          if (!hasAddress) {
                            return _AddAddressButton(controller: controller);
                          }

                          if (!hasPayment) {
                            return const _SelectPaymentPrompt();
                          }

                          return _ProceedToCheckoutButton(
                            controller: controller,
                          );
                        }),

                        SizedBox(height: Responsive.space(context, 16)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final CartController controller;
  const _TopBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.space(context, 16),
        vertical: Responsive.space(context, 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MainScreen(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                },
              ),
              Text('Your Cart', style: AppTextStyles.welcomeBackTitle(context)),
            ],
          ),
          if (controller.cartItems.isNotEmpty)
            TextButton(
              onPressed: controller.clearCart,
              child: Text(
                'Clear',
                style: AppTextStyles.termsText(
                  context,
                ).copyWith(color: AppColors.errorRed),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 140,
            height: 250,
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.shopping_cart_outlined,
                  size: 70,
                  color: AppColors.primaryGreen.withOpacity(0.3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Your Cart is Empty',
            style: AppTextStyles.welcomeBackTitle(context).copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Looks like you haven\'t added anything yet',
            style: AppTextStyles.termsText(
              context,
            ).copyWith(fontSize: 14, color: AppColors.textGray),
          ),
          const SizedBox(height: 4),
          Text(
            'Start exploring and find what you need!',
            style: AppTextStyles.termsText(
              context,
            ).copyWith(fontSize: 13, color: AppColors.textGray),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 220,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainScreen(initialIndex: 1),
                  ),
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Browse Products',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _CartItemsCard extends StatelessWidget {
  final CartController controller;
  const _CartItemsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order of ${controller.itemCount} items',
            style: AppTextStyles.welcomeBackTitle(
              context,
            ).copyWith(fontSize: 16),
          ),
          SizedBox(height: Responsive.space(context, 12)),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.cartItems.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
            itemBuilder: (_, index) => _SwipeableCartItemRow(
              item: controller.cartItems[index],
              controller: controller,
              index: index,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeableCartItemRow extends StatefulWidget {
  final CartItem item;
  final CartController controller;
  final int index;

  const _SwipeableCartItemRow({
    required this.item,
    required this.controller,
    required this.index,
  });

  @override
  State<_SwipeableCartItemRow> createState() => _SwipeableCartItemRowState();
}

class _SwipeableCartItemRowState extends State<_SwipeableCartItemRow> {
  double _dragOffset = 0;
  bool _isSwiped = false;
  static const double _deleteThreshold = -50;
  static const double _maxSwipe = -70;

  void _openProductDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: CategoryProductItem(
            variantId: widget.item.variantId,
            materialId: widget.item.variantId,
            name: widget.item.materialName,
            imageUrl: widget.item.imageUrl,
            price: widget.item.unitPriceWithGst,
          ),
        ),
      ),
    );
  }

  void _showBulkPricingSheet(BuildContext context) {
    if (!widget.item.hasTiers || widget.item.priceTiers.isEmpty) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              children: const [
                Icon(
                  Icons.local_offer_outlined,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
                const SizedBox(width: 8),
                Text(
                  'Bulk Prices Launched',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.item.materialName}, ${widget.item.sizeDimension}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...widget.item.priceTiers.map(
              (tier) => InkWell(
                onTap: () {
                  widget.controller.updateQuantity(widget.item, tier.minQty);
                  Navigator.pop(context);
                  Get.snackbar(
                    'Bulk Price Applied',
                    'Qty set to ${tier.minQty} at ₹${tier.price.toStringAsFixed(2)}/unit',
                    backgroundColor: AppColors.primaryGreen,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9F1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 10),
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
                          fontWeight: FontWeight.w700,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _resetSwipe() {
    setState(() {
      _dragOffset = 0;
      _isSwiped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _dragOffset += details.delta.dx;
              _dragOffset = _dragOffset.clamp(_maxSwipe, 0);
              _isSwiped = _dragOffset < _deleteThreshold;
            });
          },
          onHorizontalDragEnd: (details) {
            setState(() {
              if (_dragOffset < _deleteThreshold) {
                _dragOffset = _maxSwipe;
                _isSwiped = true;
              } else {
                _dragOffset = 0;
                _isSwiped = false;
              }
            });
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Delete background - minimal design
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedOpacity(
                    opacity: _isSwiped ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: GestureDetector(
                      onTap: () async {
                        // Show confirmation dialog
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Remove Item'),
                            content: Text(
                              'Remove "${widget.item.materialName}" from your cart?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: const Text('Remove'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await widget.controller.removeItem(widget.item);
                          _resetSwipe();
                        } else {
                          _resetSwipe();
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Main content
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                transform: Matrix4.translationValues(_dragOffset, 0, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: _CartItemContent(
                    item: widget.item,
                    controller: widget.controller,
                    onTap: () => _openProductDetail(context),
                    onBulkTap: () => _showBulkPricingSheet(context),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CartItemContent extends StatelessWidget {
  final CartItem item;
  final CartController controller;
  final VoidCallback onTap;
  final VoidCallback onBulkTap;

  const _CartItemContent({
    required this.item,
    required this.controller,
    required this.onTap,
    required this.onBulkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
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
                                color: Colors.black26,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.materialName}, ${item.sizeDimension}',
                          style: AppTextStyles.fieldLabel(
                            context,
                          ).copyWith(color: AppColors.textDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.hasTiers && item.priceTiers.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: onBulkTap,
                            child: const Text(
                              'Buy at wholesale price',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: Responsive.space(context, 8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.totalPriceWithGst.toStringAsFixed(2)}', // Changed from 0 to 2
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              _QuantityStepper(item: item, controller: controller),
            ],
          ),
        ],
      ),
    );
  }
}

class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final CartController controller;
  const _CartItemRow({required this.item, required this.controller});

  void _openProductDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: CategoryProductItem(
            variantId: item.variantId,
            materialId: item.variantId,
            name: item.materialName,
            imageUrl: item.imageUrl,
            price: item.unitPriceWithGst,
          ),
        ),
      ),
    );
  }

  void _showBulkPricingSheet(BuildContext context) {
    if (!item.hasTiers || item.priceTiers.isEmpty) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              children: const [
                Icon(
                  Icons.local_offer_outlined,
                  size: 18,
                  color: AppColors.primaryGreen,
                ),
                SizedBox(width: 8),
                Text(
                  'Bulk Prices Launched',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${item.materialName}, ${item.sizeDimension}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ...item.priceTiers.map(
              (tier) => InkWell(
                onTap: () {
                  controller.updateQuantity(item, tier.minQty);
                  Navigator.pop(context);
                  Get.snackbar(
                    'Bulk Price Applied',
                    'Qty set to ${tier.minQty} at ₹${tier.price.toStringAsFixed(0)}/unit',
                    backgroundColor: AppColors.primaryGreen,
                    colorText: Colors.white,
                    snackPosition: SnackPosition.BOTTOM,
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9F1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        size: 6,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 10),
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
                          fontWeight: FontWeight.w700,
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
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _openProductDetail(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
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
                                color: Colors.black26,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.materialName}, ${item.sizeDimension}',
                          style: AppTextStyles.fieldLabel(
                            context,
                          ).copyWith(color: AppColors.textDark),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.hasTiers && item.priceTiers.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => _showBulkPricingSheet(context),
                            child: const Text(
                              'Buy at wholesale price',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: Responsive.space(context, 8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${item.totalPriceWithGst.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 8),
              _QuantityStepper(item: item, controller: controller),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final CartItem item;
  final CartController controller;
  const _QuantityStepper({required this.item, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(
            icon: Icons.remove,
            onTap: () => item.quantity > 1
                ? controller.decrement(item)
                : controller.removeItem(item),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _StepperButton(
            icon: Icons.add,
            onTap: () => controller.increment(item),
          ),
        ],
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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}

class _CouponCard extends StatefulWidget {
  final CartController controller;
  const _CouponCard({required this.controller});

  @override
  State<_CouponCard> createState() => _CouponCardState();
}

class _CouponCardState extends State<_CouponCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Obx(() {
      final coupons = controller.myCoupons;
      final validCoupons = coupons.where((c) => c.isValid).toList();
      final selectedCoupon = controller.selectedCoupon.value;
      final isLoading = controller.isLoadingCoupons.value;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_offer_outlined,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Coupons',
                  style: AppTextStyles.welcomeBackTitle(
                    context,
                  ).copyWith(fontSize: 16),
                ),
                const Spacer(),
                if (selectedCoupon != null)
                  GestureDetector(
                    onTap: controller.removeSelectedCoupon,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.red.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (selectedCoupon != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryGreen.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedCoupon.couponCode,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${selectedCoupon.discountPercentage.toStringAsFixed(0)}% off on ${selectedCoupon.rewardMaterialName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Applied',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else if (validCoupons.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.local_offer_outlined,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'No coupons available',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FFF8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primaryGreen.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        size: 18,
                        color: AppColors.primaryGreen,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${validCoupons.length} coupon${validCoupons.length > 1 ? 's' : ''} available',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: _isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                          children: validCoupons
                              .map(
                                (coupon) => _CouponDropdownItem(
                                  coupon: coupon,
                                  onTap: () {
                                    controller.selectCoupon(coupon);
                                    setState(() => _isExpanded = false);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _CouponDropdownItem extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onTap;

  const _CouponDropdownItem({required this.coupon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final daysRemaining = coupon.expiryDate.difference(DateTime.now()).inDays;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FFF8),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primaryGreen.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.local_offer,
                color: AppColors.primaryGreen,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.couponCode,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    '${coupon.discountPercentage.toStringAsFixed(0)}% off on ${coupon.rewardMaterialName}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),

                  Text(
                    coupon.formattedExpiryDate,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: daysRemaining < 0
                          ? Colors.red
                          : daysRemaining <= 3
                          ? Colors.orange
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Apply',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GstinCard extends StatefulWidget {
  final CartController controller;
  const _GstinCard({required this.controller});

  @override
  State<_GstinCard> createState() => _GstinCardState();
}

class _GstinCardState extends State<_GstinCard> {
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
      text: widget.controller.gstinNumber.value,
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _onAddPressed() {
    final value = _textCtrl.text.trim();
    if (value.isNotEmpty && !widget.controller.isGstValid(value)) {
      Get.snackbar('Invalid GSTIN', 'Enter a valid GSTIN, or leave it blank.');
      return;
    }
    widget.controller.saveGstin(value);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return Obx(() {
      final saved = controller.gstinNumber.value;
      final hasGstin = saved.isNotEmpty;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: AppColors.textGray,
                ),
                SizedBox(width: Responsive.space(context, 12)),
                Expanded(
                  child: Text(
                    'Add GSTIN',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            SizedBox(height: Responsive.space(context, 10)),
            if (hasGstin)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9F1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        saved,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, 8)),
                  TextButton(
                    onPressed: () {
                      controller.removeGstin();
                      _textCtrl.clear();
                    },
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => _onAddPressed(),
                      decoration: InputDecoration(
                        hintText: 'Enter GSTIN (optional)',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.inputBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primaryGreen,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: Responsive.space(context, 8)),
                  ElevatedButton(
                    onPressed: _onAddPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    });
  }
}

class _BillDetailsCard extends StatelessWidget {
  final CartController controller;
  const _BillDetailsCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: controller.toggleBillDetails,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bill Details',
                  style: AppTextStyles.welcomeBackTitle(
                    context,
                  ).copyWith(fontSize: 16),
                ),
                Obx(
                  () => Icon(
                    controller.billDetailsExpanded.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (!controller.billDetailsExpanded.value)
              return const SizedBox.shrink();

            final checkout = controller.checkoutResponse.value;
            final subTotal =
                checkout?.paymentSummary.itemsTotalWithGst ??
                controller.subTotal;
            final couponDiscount = checkout?.paymentSummary.couponDiscount ?? 0;
            final gstTax = checkout?.paymentSummary.totalGstTax;
            final deliveryCharge = checkout?.paymentSummary.deliveryCharge ?? 0;
            final total =
                checkout?.paymentSummary.grandTotal ?? controller.total;

            // 🔎 DEBUG — mirrors the controller log, but from the UI's read of the
            // reactive value, so a stale/late rebuild would show up as a mismatch
            // between this line and the one printed in processCheckout()
            debugPrint(
              '[BillDetailsCard] 🖼️ rendering => subTotal=$subTotal, '
              'gstTax=$gstTax, couponDiscount=$couponDiscount, '
              'deliveryCharge=$deliveryCharge, total=$total, '
              'hasCheckoutResponse=${checkout != null}, '
              'localFallbackSubTotal=${controller.subTotal}, '
              'localFallbackTotal=${controller.total}',
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(height: 24),
                _BillRow(
                  label: 'Sub Total (Inclusive of GST)',
                  value: '₹${subTotal.toStringAsFixed(2)}',
                ),
                // if (gstTax != null)
                //   _BillRow(
                //     label: 'GST',
                //     value: '₹${gstTax.toStringAsFixed(2)}',
                //   ),
                _BillRow(
                  label: 'Discount',
                  value: couponDiscount > 0
                      ? '-₹${couponDiscount.toStringAsFixed(2)}'
                      : '₹0.00',
                  valueColor: couponDiscount > 0
                      ? AppColors.primaryGreen
                      : null,
                ),
                _BillRow(
                  label: 'Delivery Charge',
                  value: deliveryCharge > 0
                      ? '₹${deliveryCharge.toStringAsFixed(2)}'
                      : '₹0.00',
                  valueColor: deliveryCharge > 0
                      ? null
                      : AppColors.primaryGreen,
                ),

                const Divider(height: 24),
                _BillRow(
                  label: 'Total',
                  value: '₹${total.toStringAsFixed(2)}',
                  bold: true,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _CancellationPolicyCard extends StatelessWidget {
  final CartController controller;
  const _CancellationPolicyCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: controller.toggleCancellationPolicy,
            child: Row(
              children: [
                const Icon(
                  Icons.description_outlined,
                  color: AppColors.textGray,
                  size: 20,
                ),
                SizedBox(width: Responsive.space(context, 10)),
                Expanded(
                  child: Text(
                    'Cancellation Policy',
                    style: AppTextStyles.fieldLabel(context),
                  ),
                ),
                Obx(
                  () => Icon(
                    controller.cancellationPolicyExpanded.value
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            if (!controller.cancellationPolicyExpanded.value) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Free cancellation within 24 hours of placing your order. '
                'Cancellations made between 24 and 48 hours are eligible for a 50% refund. '
                'Orders cancelled after 48 hours are not eligible for a refund.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;
  const _BillRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: bold ? AppColors.textDark : AppColors.textGray,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor ?? AppColors.textDark,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  final CartController controller;

  const _PaymentMethodSelector({required this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      // key removed here — the outer widget already carries
      // CartScreen.paymentMethodKey via its constructor's `key` param,
      // and GlobalKeys must only ever appear on ONE widget in the tree.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Obx(
            () => Text(
              controller.hasSelectedPaymentMethod.value
                  ? 'Selected — tap "Proceed to Checkout" below to continue'
                  : 'Choose how you\'d like to pay to continue',
              style: const TextStyle(fontSize: 12, color: AppColors.textGray),
            ),
          ),
          const SizedBox(height: 12),
          Obx(() {
            final isSelected =
                controller.hasSelectedPaymentMethod.value &&
                controller.selectedPaymentMethod.value == 'COD';
            return _PaymentMethodTile(
              isSelected: isSelected,
              icon: Icons.money_rounded,
              title: 'Cash on Delivery (COD)',
              subtitle: 'Pay when you receive your order',
              onTap: () => controller.selectPaymentMethod('COD'),
            );
          }),
          const SizedBox(height: 8),
          Obx(() {
            final isSelected =
                controller.hasSelectedPaymentMethod.value &&
                controller.selectedPaymentMethod.value == 'RAZORPAY';
            return _PaymentMethodTile(
              isSelected: isSelected,
              icon: Icons.credit_card_rounded,
              title: 'Pay Online',
              subtitle: 'UPI, Card, Net Banking, or Wallet via Razorpay',
              onTap: () => controller.selectPaymentMethod('RAZORPAY'),
              isOnline: true,
            );
          }),
        ],
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  final bool isSelected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isOnline;
  const _PaymentMethodTile({
    required this.isSelected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isOnline
        ? const Color(0xFF1A73E8)
        : AppColors.primaryGreen;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? (isOnline ? const Color(0xFFE8F0FE) : const Color(0xFFF0F9F1))
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.inputBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : const Color(0xFFF3F3F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : AppColors.textGray,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? activeColor : AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? activeColor : Colors.transparent,
                border: Border.all(
                  color: isSelected ? activeColor : AppColors.inputBorder,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> _requireRegistrationForGuest(BuildContext context) async {
  // Already authenticated
  if (await AuthGate.isLoggedIn()) {
    debugPrint('[CartScreen] User already logged in');
    return true;
  }

  debugPrint('[CartScreen] Guest user detected → opening SignupView');

  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const SignupView(isModal: true)),
  );

  if (!context.mounted) {
    return false;
  }

  debugPrint('[CartScreen] SignupView returned: $result');

  // Do not rely only on Navigator result.
  // Check the actual authentication session.
  final loggedIn = await AuthGate.isLoggedIn();

  debugPrint('[CartScreen] Authentication after registration: $loggedIn');

  return loggedIn;
}

/// ═══════════════════════════════════════════════════════════════════════
/// CHANGED: gated behind AuthGate — guests hit this before they have
/// any address, so this is the natural first checkout gate.
/// ═══════════════════════════════════════════════════════════════════════
class _AddAddressButton extends StatelessWidget {
  final CartController controller;

  const _AddAddressButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _requestAddress(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Add Your Address',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _requestAddress(BuildContext context) async {
    debugPrint('[CartScreen] Add Address tapped');

    final authenticated = await _requireRegistrationForGuest(context);

    if (!authenticated) {
      debugPrint(
        '[CartScreen] Registration cancelled/failed → staying on cart',
      );
      return;
    }

    if (!context.mounted) return;

    debugPrint('[CartScreen] Authentication successful → refreshing cart');

    await controller.fetchCart(showLoader: false);

    if (!context.mounted) return;

    // Show the address modal and wait for the result
    final result = await _showAddressModal(context);

    // If the user successfully saved an address, scroll to payment method
    if (result == true) {
      if (!context.mounted) return;

      debugPrint(
        '[CartScreen] Address saved successfully → scrolling to payment',
      );

      // Small delay to let the UI rebuild with the new address
      await Future.delayed(const Duration(milliseconds: 300));
      await CartScreen.scrollToPaymentMethod();
    }
  }

  Future<bool?> _showAddressModal(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: AddressChangeModal(controller: Get.find<CartController>()),
        ),
      ),
    );
  }
}

class _SelectPaymentPrompt extends StatelessWidget {
  const _SelectPaymentPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.payment_outlined, color: AppColors.textGray, size: 18),
          SizedBox(width: 8),
          Text(
            'Select a payment method to continue',
            style: TextStyle(
              color: AppColors.textGray,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ═══════════════════════════════════════════════════════════════════════
/// CHANGED: second checkout gate (belt-and-suspenders — a logged-in-only
/// address means most guests never reach here, but this covers any path
/// where a session expired between adding the address and checking out).
/// ═══════════════════════════════════════════════════════════════════════
class _ProceedToCheckoutButton extends StatelessWidget {
  final CartController controller;

  const _ProceedToCheckoutButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isProcessing = controller.isCheckingOut.value;

      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isProcessing ? null : () => _requestCheckout(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isProcessing)
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else ...[
                const Text(
                  'Proceed to Checkout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.payment, color: Colors.white, size: 18),
              ],
            ],
          ),
        ),
      );
    });
  }

  Future<void> _requestCheckout(BuildContext context) async {
    debugPrint('[CartScreen] Proceed to Checkout tapped');

    final wasLoggedIn = await AuthGate.isLoggedIn();

    // ------------------------------------------------------------
    // GUEST USER
    // ------------------------------------------------------------
    if (!wasLoggedIn) {
      debugPrint('[CartScreen] Guest user → opening registration');

      final registered = await _requireRegistrationForGuest(context);

      if (!registered) {
        debugPrint(
          '[CartScreen] Registration cancelled/failed → staying on cart',
        );
        return;
      }

      if (!context.mounted) return;

      debugPrint(
        '[CartScreen] Registration successful — new CartScreen took over',
      );

      // Refresh cart and load profile/address
      await controller.fetchCart(showLoader: false);

      // Load the user's address from profile
      try {
        final profile = await ApiService.getProfile();
        final address = AddressModel.fromJson(profile);
        // This will trigger the _addressWorker which will scroll
        controller.selectedAddress.value = address;
        debugPrint('[CartScreen] Address loaded, worker will handle scroll');
      } catch (e) {
        debugPrint('[CartScreen] Failed to load address: $e');
      }

      // Wait for the UI to build with the address
      await Future.delayed(const Duration(milliseconds: 500));

      if (!context.mounted) return;

      // If address is loaded but worker didn't trigger, scroll manually
      if (controller.selectedAddress.value != null) {
        debugPrint(
          '[CartScreen] Scrolling to payment method after registration',
        );
        await CartScreen.scrollToPaymentMethod();
      }

      return;
    }

    // ------------------------------------------------------------
    // ALREADY LOGGED IN — proceed straight to checkout
    // ------------------------------------------------------------
    if (!context.mounted) return;

    debugPrint('[CartScreen] Already authenticated → proceeding to checkout');

    await controller.fetchCart(showLoader: false);

    if (!context.mounted) return;

    await _proceedToCheckout(context);
  }

  Future<void> _proceedToCheckout(BuildContext context) async {
    final address = controller.selectedAddress.value;
    final deliveryDate = controller.selectedDeliveryDate.value;
    final deliveryTime = controller.selectedDeliveryTime.value;

    if (address == null || deliveryDate == null || deliveryTime == null) {
      Get.snackbar(
        'Missing Information',
        'Please add your address, delivery date, and delivery time',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutConfirmationModal(controller: controller),
    );

    if (confirmed != true) {
      // User cancelled - scroll to payment method
      if (context.mounted) {
        debugPrint(
          '[CartScreen] Checkout cancelled - scrolling to payment method',
        );
        // Small delay for modal to close
        await Future.delayed(const Duration(milliseconds: 300));
        if (context.mounted) {
          await CartScreen.scrollToPaymentMethod();
        }
      }
      return;
    }

    controller.isCheckingOut.value = true;

    final orderResult = await controller.placeOrder(
      shippingAddress: address.address,
      pincode: address.pincode,
      deliveryDate: deliveryDate,
      deliveryTime: deliveryTime,
    );

    if (orderResult != null) {
      Get.offAll(() => OrderSuccessScreen(order: orderResult));
      return;
    }

    controller.isCheckingOut.value = false;
  }
}

class _OrderDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isBold;
  final Color? valueColor;
  const _OrderDetailRow(
    this.label,
    this.value, {
    required this.icon,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _CheckoutConfirmationModal extends StatelessWidget {
  final CartController controller;
  const _CheckoutConfirmationModal({required this.controller});

  @override
  Widget build(BuildContext context) {
    final address = controller.selectedAddress.value;
    final checkout = controller.checkoutResponse.value;
    final vehicle = controller.selectedVehicle.value;
    final paymentMethod = controller.selectedPaymentMethod.value;

    return Container(
      padding: const EdgeInsets.only(top: 5, left: 16, right: 16, bottom: 45),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Order Summary',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: paymentMethod == 'COD'
                  ? Colors.green.shade50
                  : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: paymentMethod == 'COD'
                    ? Colors.green.shade200
                    : Colors.blue.shade200,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  paymentMethod == 'COD'
                      ? Icons.money_rounded
                      : Icons.credit_card_rounded,
                  size: 16,
                  color: paymentMethod == 'COD'
                      ? Colors.green.shade700
                      : Colors.blue.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'Payment: $paymentMethod',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: paymentMethod == 'COD'
                        ? Colors.green.shade700
                        : Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Delivery Address',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            address?.address ?? '',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            'Pincode: ${address?.pincode ?? ''}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          const Text(
            'Delivery Date & Time',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.selectedDeliveryDate.value ?? ''} '
            '${controller.selectedDeliveryTime.value != null ? "at ${controller.selectedDeliveryTime.value}" : ""}',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          if (vehicle != null) ...[
            const Text(
              'Vehicle',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '${vehicle.vehicleName} (${vehicle.vehicleNumber})',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
          ],
          if (checkout != null) ...[
            const Divider(),
            const Text(
              'Payment Summary',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 8),
            _SummaryRow(
              'Items Total',
              '₹${checkout.paymentSummary.itemsTotalWithGst.toStringAsFixed(2)}',
            ),
            _SummaryRow(
              'GST',
              '₹${checkout.paymentSummary.totalGstTax.toStringAsFixed(2)}',
            ),
            _SummaryRow(
              'Delivery Charge',
              '₹${checkout.paymentSummary.deliveryCharge.toStringAsFixed(2)}',
            ),
            if (checkout.paymentSummary.couponDiscount > 0)
              _SummaryRow(
                'Coupon Discount',
                '-₹${checkout.paymentSummary.couponDiscount.toStringAsFixed(0)}',
                isDiscount: true,
              ),
            const Divider(),
            _SummaryRow(
              'Grand Total',
              '₹${checkout.paymentSummary.grandTotal.toStringAsFixed(2)}',
              isTotal: true,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      checkout.deliveryConfig.distanceMessage,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(result: false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isCheckingOut.value
                        ? null
                        : () => Get.back(result: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: controller.isCheckingOut.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Place Order',
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
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final bool isDiscount;
  const _SummaryRow(
    this.label,
    this.value, {
    this.isTotal = false,
    this.isDiscount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isDiscount ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }
}
