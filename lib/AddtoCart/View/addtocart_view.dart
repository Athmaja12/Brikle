import 'package:brikle/AddtoCart/Controller/addtocart_provider.dart';
import 'package:brikle/AddtoCart/Model/addtocart_model.dart';
import 'package:brikle/AppStyle/appcolors.dart';
import 'package:brikle/AppStyle/appstyle.dart';
import 'package:brikle/AppStyle/responsive.dart';
import 'package:brikle/BottomNavigation/bottomnavigation.dart';
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
          child: Obx(
            () => controller.cartItems.isEmpty
                ? const _EmptyCart()
                : ListView(
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
                      SizedBox(height: Responsive.space(context, 12)),
                      _CancellationPolicyCard(),
                      SizedBox(height: Responsive.space(context, 16)),
                      _AddAddressButton(),
                      SizedBox(height: Responsive.space(context, 16)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────
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
                onPressed: () => Navigator.pop(context),
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

// ── Empty state ───────────────────────────────────────────────────────────
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

// ── Cart items card ───────────────────────────────────────────────────────
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
            itemBuilder: (_, index) {
              return _CartItemRow(
                item: controller.cartItems[index],
                controller: controller,
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Single cart item row — DELETE + BULK PRICING added ───────────────────
class _CartItemRow extends StatelessWidget {
  final CartItem item;
  final CartController controller;
  const _CartItemRow({required this.item, required this.controller});

  // ── DELETE: confirmation bottom sheet ──────────────────────────────────
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
            // drag handle
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
                // Cancel
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
                // Remove
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

  // ── BULK PRICING: bottom sheet matching category/product detail UI ─────
  void _showBulkPricingSheet(BuildContext context) {
    // Guard: nothing to show if no tiers
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
            // drag handle
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

            // Header — matches productdetails_page.dart bulk pricing block
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

            // Tier rows — same layout as _ProductCard._showBulkPricingDialog
            ...item.priceTiers.map(
              (tier) => InkWell(
                onTap: () {
                  // Apply tier: update qty to the tier minimum so the
                  // discounted unit price kicks in (mirrors category page)
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
                    // matches productdetails_page.dart: Color(0xFFF0F9F1)
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
                      // "Apply" tap hint
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product image
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

        // Name + bulk price link
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

              // ── BULK PRICING LINK (was onTap: () {} — now wired) ──────
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
                      Text(
                        'Buy at wholesale price',
                        style: const TextStyle(
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

        // Price + DELETE button
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${item.totalPriceWithGst.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 6),
            // ── DELETE BUTTON ─────────────────────────────────────────────
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
    );
  }
}

// ── Qty stepper ───────────────────────────────────────────────────────────
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

// ── Coupon card (unchanged) ───────────────────────────────────────────────
class _CouponCard extends StatelessWidget {
  final CartController controller;
  const _CouponCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final textController = TextEditingController();
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
            'Get Discount',
            style: AppTextStyles.welcomeBackTitle(
              context,
            ).copyWith(fontSize: 16),
          ),
          SizedBox(height: Responsive.space(context, 10)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  decoration: InputDecoration(
                    hintText: 'Enter Coupon Code',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: AppColors.inputBorder),
                    ),
                  ),
                ),
              ),
              SizedBox(width: Responsive.space(context, 10)),
              ElevatedButton(
                onPressed: () => controller.applyCoupon(textController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── GSTIN card (unchanged) ────────────────────────────────────────────────
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

// ── Bill details card (unchanged) ─────────────────────────────────────────
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
          _BillRow(
            label: 'Delivery Charge',
            value: CartController.staticDeliveryChargeLabel,
            valueColor: AppColors.primaryGreen,
          ),
          _BillRow(
            label: 'Handling Charge',
            value: '₹${CartController.staticHandlingCharge.toStringAsFixed(0)}',
          ),
          const Divider(height: 24),
          _BillRow(
            label: 'Total',
            value: '₹${controller.total.toStringAsFixed(0)}',
            bold: true,
          ),
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

// ── Cancellation policy card (unchanged) ──────────────────────────────────
class _CancellationPolicyCard extends StatelessWidget {
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
            child: Text(
              'Cancellation Policy',
              style: AppTextStyles.fieldLabel(context),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down),
        ],
      ),
    );
  }
}

// ── Add address button (unchanged) ────────────────────────────────────────
class _AddAddressButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: navigate to address selection/checkout flow
        },
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
}
