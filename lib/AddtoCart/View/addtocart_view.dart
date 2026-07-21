// lib/AddtoCart/View/addtocart_view.dart
// Only _ProceedToCheckoutButton and _showOrderSuccessPopup are changed.
// All other classes are identical to what you already have.

import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/View/addresschange_modal.dart';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/AddtoCart/Model/address_model.dart';
import 'package:brikle/AddtoCart/View/ordersuccess_screen.dart'
    show OrderSuccessScreen;
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/BottomNavigation/mainscreen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F6),
      body: SafeArea(
        child: Obx(() {
          // Show full screen loader while placing order
          if (controller.isCheckingOut.value) {
            return const Center(child: CircularProgressIndicator());
          }

          // Initial cart loading
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return _CartBody();
        }),
      ),
    );
  }
}

class _CartBody extends GetView<CartController> {
  _CartBody();

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
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.space(context, 16),
                      ),
                      children: [
                        SizedBox(height: Responsive.space(context, 12)),
                        _CartItemsCard(controller: controller),
                        SizedBox(height: Responsive.space(context, 12)),
                        _CouponCard(controller: controller),
                        SizedBox(height: Responsive.space(context, 12)),
                        _GstinCard(controller: controller),
                        SizedBox(height: Responsive.space(context, 12)),
                        _BillDetailsCard(controller: controller),
                        SizedBox(height: Responsive.space(context, 16)),
                        Obx(() {
                          final hasAddress =
                              controller.selectedAddress.value != null;
                          if (!hasAddress) return const SizedBox.shrink();
                          return Column(
                            children: [
                              _PaymentMethodSelector(controller: controller),
                              SizedBox(height: Responsive.space(context, 16)),
                            ],
                          );
                        }),
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
                      builder: (_) =>
                          const MainScreen(initialIndex: 1), // Category tab
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
          const Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            'Your cart is empty',
            style: AppTextStyles.welcomeBackTitle(
              context,
            ).copyWith(fontSize: 16),
          ),
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
            itemBuilder: (_, index) => _CartItemRow(
              item: controller.cartItems[index],
              controller: controller,
            ),
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

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.inputBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.delete_outline_rounded,
              size: 40,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            const Text(
              'Remove Item?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '${item.materialName}, ${item.sizeDimension}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w600,
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
                      backgroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Remove',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
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
                const SizedBox(height: 4),
                if (item.hasTiers && item.priceTiers.isNotEmpty)
                  GestureDetector(
                    onTap: () => _showBulkPricingSheet(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_offer_outlined,
                          size: 13,
                          color: AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Buy at wholesale price',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryGreen,
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: Responsive.space(context, 8)),
                _QuantityStepper(item: item, controller: controller),
              ],
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
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () => _showDeleteSheet(context),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    size: 18,
                    color: Colors.red.shade500,
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

// lib/AddtoCart/View/addtocart_view.dart
// Replace only the _CouponCard class with this code

// ═══════════════════════════════════════════════════════════════════════════
// _CouponCard - Dropdown-style coupon selector (collapsed by default)
// ═══════════════════════════════════════════════════════════════════════════
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
            // ── Header row (always visible) ─────────────────────────────
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

            // ── Selected coupon chip (shown collapsed or expanded) ──────
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
            // ── Loading state ────────────────────────────────────────────
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
            // ── No coupons available ─────────────────────────────────────
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
            // ── Dropdown trigger + expandable list ───────────────────────
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

// ── Coupon Item Widget ──────────────────────────────────────
class _CouponDropdownItem extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onTap;

  const _CouponDropdownItem({required this.coupon, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
                      color:
                          coupon.expiryDate.difference(DateTime.now()).inDays <
                              3
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

class _GstinCard extends StatelessWidget {
  final CartController controller;
  const _GstinCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.description_outlined, color: AppColors.textGray),
          SizedBox(width: Responsive.space(context, 12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add GSTIN',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Claim GST input credit on your order',
                  style: AppTextStyles.termsText(context),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: controller.addGstin,
            child: const Text(
              'Add',
              style: TextStyle(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// class _DeliveryDateCard extends StatelessWidget {
//   final CartController controller;
//   const _DeliveryDateCard({required this.controller});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//       ),
//       padding: const EdgeInsets.all(16),
//       child: Row(
//         children: [
//           const Icon(
//             Icons.calendar_today_outlined,
//             color: AppColors.primaryGreen,
//           ),
//           SizedBox(width: Responsive.space(context, 12)),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Text(
//                   'Delivery Date',
//                   style: TextStyle(fontWeight: FontWeight.w600),
//                 ),
//                 Obx(() {
//                   final date = controller.selectedDeliveryDate.value;
//                   return Text(
//                     date != null ? 'Scheduled: $date' : 'Select delivery date',
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: date != null
//                           ? AppColors.textDark
//                           : AppColors.textGray,
//                     ),
//                   );
//                 }),
//               ],
//             ),
//           ),
//           Obx(() {
//             final date = controller.selectedDeliveryDate.value;
//             return IconButton(
//               onPressed: () => _showDatePicker(context, controller),
//               icon: Icon(
//                 date != null ? Icons.edit : Icons.add,
//                 color: AppColors.primaryGreen,
//                 size: 20,
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }

//   void _showDatePicker(BuildContext context, CartController controller) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now().add(const Duration(days: 1)),
//       firstDate: DateTime.now().add(const Duration(days: 1)),
//       lastDate: DateTime.now().add(const Duration(days: 30)),
//     );
//     if (picked != null) {
//       controller.selectedDeliveryDate.value = picked
//           .toIso8601String()
//           .split('T')
//           .first;
//     }
//   }
// }

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bill Details',
                style: AppTextStyles.welcomeBackTitle(
                  context,
                ).copyWith(fontSize: 16),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
          const Divider(height: 24),
          _BillRow(
            label: 'Sub Total (Inclusive of GST)',
            value: '₹${controller.subTotal.toStringAsFixed(0)}',
          ),
          _BillRow(
            label: 'Discount',
            value: '₹${CartController.staticDiscount.toStringAsFixed(0)}',
          ),
          Obx(() {
            final checkout = controller.checkoutResponse.value;
            final deliveryCharge = checkout?.paymentSummary.deliveryCharge ?? 0;
            return _BillRow(
              label: 'Delivery Charge',
              value: deliveryCharge > 0
                  ? '₹${deliveryCharge.toStringAsFixed(0)}'
                  : 'FREE',
              valueColor: deliveryCharge > 0 ? null : AppColors.primaryGreen,
            );
          }),
          _BillRow(
            label: 'Handling Charge',
            value: '₹${CartController.staticHandlingCharge.toStringAsFixed(0)}',
          ),
          const Divider(height: 24),
          Obx(() {
            final checkout = controller.checkoutResponse.value;
            final total =
                checkout?.paymentSummary.grandTotal ?? controller.total;
            return _BillRow(
              label: 'Total',
              value: '₹${total.toStringAsFixed(0)}',
              bold: true,
            );
          }),
          const Divider(height: 24),
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
            if (!controller.cancellationPolicyExpanded.value)
              return const SizedBox.shrink();
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
  const _PaymentMethodSelector({required this.controller});

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
                controller.selectedPaymentMethod.value == 'Online';
            return _PaymentMethodTile(
              isSelected: isSelected,
              icon: Icons.credit_card_rounded,
              title: 'Online Payment',
              subtitle: 'Pay via UPI, Card, or Net Banking',
              onTap: () => controller.selectPaymentMethod('Online'),
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

class _AddAddressButton extends StatelessWidget {
  final CartController controller;
  const _AddAddressButton({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showAddressModal(context),
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

  void _showAddressModal(BuildContext context) {
    showModalBottomSheet(
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

// ═══════════════════════════════════════════════════════════════════════════
// FIXED: _ProceedToCheckoutButton
// BUG: After showModalBottomSheet resolves and placeOrder() awaits,
//      the original BuildContext is stale (StatelessWidget has no `mounted`).
//      Calling showDialog(context: staleContext) crashes or silently fails.
// FIX: Use Get.dialog() which uses GetX's internal context — always valid.
// ═══════════════════════════════════════════════════════════════════════════
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
          onPressed: isProcessing ? null : () => _proceedToCheckout(context),
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

  Future<void> _proceedToCheckout(BuildContext context) async {
    final address = controller.selectedAddress.value;
    final deliveryDate = controller.selectedDeliveryDate.value;
    final deliveryTime = controller.selectedDeliveryTime.value; // NEW

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

    if (confirmed != true) return;

    controller.isCheckingOut.value = true;

    final orderResult = await controller.placeOrder(
      shippingAddress: address.address,
      pincode: address.pincode,
      deliveryDate: deliveryDate,
      deliveryTime: deliveryTime, // NEW
    );

    if (orderResult != null) {
      Get.offAll(() => const OrderSuccessScreen());
      return;
    }

    controller.isCheckingOut.value = false;
  }

  void _showOrderSuccessDialog(OrderPlacedResponse order) {
    // FIX: Get.dialog() instead of showDialog(context: context, ...).
    // After two awaits (showModalBottomSheet + placeOrder), the original
    // context from build() is stale. Get.dialog uses GetX's navigator key
    // internally so it always works regardless of widget lifecycle.
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 64,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order Placed Successfully! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Order #${order.orderDetails.id}',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                order.message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Order details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _OrderDetailRow(
                      'Payment Method',
                      order.orderDetails.paymentMethod,
                      icon: Icons.payments_outlined,
                    ),
                    const Divider(height: 16),
                    _OrderDetailRow(
                      'Payment Status',
                      order.orderDetails.paymentStatus,
                      icon: Icons.check_circle_outline,
                      valueColor: Colors.green,
                    ),
                    const Divider(height: 16),
                    _OrderDetailRow(
                      'Order Status',
                      order.orderDetails.orderStatus,
                      icon: Icons.receipt_long_outlined,
                      valueColor: Colors.orange,
                    ),
                    const Divider(height: 16),
                    _OrderDetailRow(
                      'Total Amount',
                      '₹${order.orderDetails.grandTotal}',
                      icon: Icons.currency_rupee,
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _OrderDetailRow(
                      'Delivery Date',
                      order.orderDetails.requestedDeliveryDate,
                      icon: Icons.calendar_today_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Shipping address
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Shipping Address',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                            ),
                          ),
                          Text(
                            order.orderDetails.shippingAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Continue Shopping button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // FIX: Get.back() closes the dialog cleanly,
                    // then offAllNamed navigates to home removing all routes.
                    Get.back();
                    Get.offAllNamed('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continue Shopping',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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

// ── Checkout Confirmation Modal ────────────────────────────────────────────
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
              '₹${checkout.paymentSummary.itemsTotalWithGst.toStringAsFixed(0)}',
            ),
            _SummaryRow(
              'GST',
              '₹${checkout.paymentSummary.totalGstTax.toStringAsFixed(0)}',
            ),
            _SummaryRow(
              'Delivery Charge',
              '₹${checkout.paymentSummary.deliveryCharge.toStringAsFixed(0)}',
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
              '₹${checkout.paymentSummary.grandTotal.toStringAsFixed(0)}',
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
